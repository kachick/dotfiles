package main

import (
	"bytes"
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"

	"github.com/kachick/dotfiles/pkgs/by-name/gi/git-x/internal/gitcmd"
)

type menuMode string

const (
	menuModeAuto      menuMode = ""
	menuModeWorktrees menuMode = "worktrees"
	menuModeBranches  menuMode = "branches"
	menuModeCommits   menuMode = "commits"
	menuModeTags      menuMode = "tags"
	menuModeRepos     menuMode = "repos"
)

func menuModeNames() []string {
	return []string{
		string(menuModeWorktrees),
		string(menuModeBranches),
		string(menuModeCommits),
		string(menuModeTags),
		string(menuModeRepos),
	}
}

const (
	menuSwitchKeys = "ctrl-w,ctrl-b,ctrl-l,ctrl-t,ctrl-r"
	menuNavHeader  = "^W: worktrees | ^B: branches | ^L: commits | ^T: tags | ^R: repos"

	menuActionRefresh            = "Refresh default branch (git x refresh)"
	menuActionDeleteMerged       = "Delete merged branches (git x delete-merged-branches)"
	menuActionDeleteMergedWithPR = "Delete merged branches + PRs (git x delete-merged-branches --pr)"
	menuActionWTCommits          = "Show worktree commits"
	menuActionWTPR               = "Check out PR worktree (git x wt pr)"
	menuActionWTPromote          = "Promote current branch (git x wt promote)"
	menuActionBranchSwitch       = "Switch / checkout worktree"
	menuActionBranchShow         = "Show tip commit details"
	menuActionCommitDetail       = "Show commit details"
	menuActionCommitBrowse       = "Open in browser (gh browse)"
	menuActionCommitRevert       = "Revert commit (git revert)"
	menuActionTagShow            = "Show tag commit details"
	menuActionTagBrowse          = "Open in browser (gh browse)"
	menuActionRepoSwitch         = "Switch to repository (cd)"
	menuActionRepoClone          = "Clone repository (git x get)"
)

type menuStepResult struct {
	nextMode  menuMode
	commitDir string
	done      bool
}

type menuBranchEntry struct {
	Name       string
	Scope      string
	ShortDate  string
	RelDate    string
	AuthorName string
	Subject    string
	IsCurrent  bool
	IsDefault  bool
	IsMerged   bool
	IsMine     bool
}

type menuTagEntry struct {
	Name      string
	ShortDate string
	RelDate   string
	Subject   string
}

type menuInteractiveUI struct {
	wtUI             wtInteractiveUI
	selectMenuItem   func(mode menuMode, fzfArgs []string, input io.Reader, stderr io.Writer) (selectChoice, error)
	selectCommitItem func(gitDir string, fzfArgs []string, stderr io.Writer) (selectChoice, error)
	chooseAction     func(header string, options []string, stderr io.Writer) (string, error)
	inputText        func(prompt, placeholder string, stderr io.Writer) (string, error)
	runRefresh       func(workDir string, stderr io.Writer) error
	runDeleteMerged  func(pr bool, workDir string, stderr io.Writer) error
	runWTPR          func(spec, workDir string, stdout, stderr io.Writer) error
	runWTPromote     func(workDir string, stdout, stderr io.Writer) error
	runRepoClone     func(spec string, stdout, stderr io.Writer) error
	showRevDetail    func(workDir, rev string, stderr io.Writer) error
	browseRev        func(workDir, rev string, stderr io.Writer) error
	revertRev        func(workDir, rev string, stderr io.Writer) error
}

func (ui menuInteractiveUI) withDefaults() menuInteractiveUI {
	ui.wtUI = ui.wtUI.withDefaults()
	customSelectMenuItem := ui.selectMenuItem != nil
	if ui.selectMenuItem == nil {
		ui.selectMenuItem = selectMenuItemWithFzf
	}
	if ui.selectCommitItem == nil {
		if customSelectMenuItem {
			selectFn := ui.selectMenuItem
			ui.selectCommitItem = func(gitDir string, fzfArgs []string, stderr io.Writer) (selectChoice, error) {
				r := gitcmd.New(gitDir, stderr, stderr)
				var logInput bytes.Buffer
				if r.Ok("rev-parse", "--verify", "--quiet", "HEAD^{commit}") {
					rawLog, err := r.OutputRaw("log", "--format="+defaultLogFormat, "--date=short", "--color=always")
					if err != nil {
						return selectChoice{}, err
					}
					logInput.Write(rawLog)
				}
				return selectFn(menuModeCommits, fzfArgs, &logInput, stderr)
			}
		} else {
			ui.selectCommitItem = selectMenuCommitStreaming
		}
	}
	if ui.chooseAction == nil {
		ui.chooseAction = chooseMenuActionWithGum
	}
	if ui.inputText == nil {
		ui.inputText = inputTextWithGum
	}
	if ui.runRefresh == nil {
		ui.runRefresh = func(workDir string, stderr io.Writer) error {
			return runRefresh(nil, workDir, stderr, stderr)
		}
	}
	if ui.runDeleteMerged == nil {
		ui.runDeleteMerged = func(pr bool, workDir string, stderr io.Writer) error {
			var args []string
			if pr {
				args = []string{"--pr"}
			}
			return runDeleteMergedBranches(args, workDir, stderr, stderr)
		}
	}
	if ui.runWTPR == nil {
		ui.runWTPR = func(spec, workDir string, stdout, stderr io.Writer) error {
			return wtRunPRWithDeps([]string{spec}, workDir, wtPRDeps{}, stdout, stderr)
		}
	}
	if ui.runWTPromote == nil {
		ui.runWTPromote = func(workDir string, stdout, stderr io.Writer) error {
			return wtRunPromote(nil, workDir, stdout, stderr)
		}
	}
	if ui.runRepoClone == nil {
		ui.runRepoClone = func(spec string, stdout, stderr io.Writer) error {
			return runGet([]string{spec}, stdout, stderr)
		}
	}
	if ui.showRevDetail == nil {
		ui.showRevDetail = func(workDir, rev string, stderr io.Writer) error {
			return renderPlainCommitInDir(workDir, rev, stderr, stderr)
		}
	}
	if ui.browseRev == nil {
		ui.browseRev = func(workDir, rev string, stderr io.Writer) error {
			cmd := exec.Command("gh", "browse", rev)
			if workDir != "" {
				cmd.Dir = workDir
			}
			cmd.Stdout = stderr
			cmd.Stderr = stderr
			return cmd.Run()
		}
	}
	if ui.revertRev == nil {
		ui.revertRev = func(workDir, rev string, stderr io.Writer) error {
			return gitcmd.New(workDir, stderr, stderr).Stream("revert", rev)
		}
	}
	return ui
}

func parseMenuMode(raw string) (menuMode, error) {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "", "auto":
		return menuModeAuto, nil
	case "wt", "worktree", "worktrees":
		return menuModeWorktrees, nil
	case "br", "branch", "branches":
		return menuModeBranches, nil
	case "log", "logs", "commit", "commits":
		return menuModeCommits, nil
	case "tag", "tags":
		return menuModeTags, nil
	case "repo", "repos", "repositories":
		return menuModeRepos, nil
	default:
		return "", fmt.Errorf("unknown menu mode %q (expected worktrees, branches, commits, tags, or repos)", raw)
	}
}

func modeFromSwitchKey(key string) (menuMode, bool) {
	switch key {
	case "ctrl-w":
		return menuModeWorktrees, true
	case "ctrl-b":
		return menuModeBranches, true
	case "ctrl-l":
		return menuModeCommits, true
	case "ctrl-t":
		return menuModeTags, true
	case "ctrl-r":
		return menuModeRepos, true
	default:
		return "", false
	}
}

func selectMenuItemWithFzf(_ menuMode, fzfArgs []string, input io.Reader, stderr io.Writer) (selectChoice, error) {
	cmd := exec.Command("fzf", fzfArgs...)
	cmd.Stdin = input
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			switch exitErr.ExitCode() {
			case 130:
				return selectChoice{}, gitcmd.ErrSelectionCanceled
			case 1:
				choice := parseFzfSelectOutput(out.String())
				if choice.Query == "" && choice.Key == "" && choice.Path == "" {
					return selectChoice{}, gitcmd.ErrSelectionCanceled
				}
				return choice, nil
			}
		}
		return selectChoice{}, fmt.Errorf("fzf failed: %w", err)
	}
	return parseFzfSelectOutput(out.String()), nil
}

func chooseMenuActionWithGum(header string, options []string, stderr io.Writer) (string, error) {
	args := make([]string, 0, 2+len(options))
	args = append(args, "choose", "--header="+header)
	args = append(args, options...)
	return runGumOutput(args, stderr)
}

func renderPlainCommitInDir(workDir, revRaw string, stdout, stderr io.Writer) error {
	rev := cleanRev(revRaw)
	if rev == "" {
		return nil
	}
	cmd := exec.Command("git", "show", "--color=always", rev)
	if workDir != "" {
		cmd.Dir = workDir
	}
	return renderCmdPipeline(cmd, stdout, stderr)
}

func renderTagPreview(workDir, tag string, stdout, stderr io.Writer) error {
	tag = strings.TrimSpace(tag)
	if tag == "" {
		return nil
	}
	cmd := exec.Command("git", "show", "--color=always", tag)
	if workDir != "" {
		cmd.Dir = workDir
	}
	return renderCmdPipeline(cmd, stdout, stderr)
}

func collectMenuBranches(r *gitcmd.Runner, defaultBranch, currentBranch string) ([]menuBranchEntry, error) {
	userEmail, _ := r.Output("config", "--get", "user.email")
	userEmail = strings.TrimSpace(userEmail)

	mergedTarget := gitcmd.ResolveTargetRef(r, defaultBranch)
	mergedSet := make(map[string]bool)
	if mergedTarget != "" {
		if rawMerged, err := r.OutputRaw("for-each-ref", "--merged="+mergedTarget, "--format=%(refname:short)", "refs/heads/", "refs/remotes/origin/"); err == nil {
			for line := range bytes.SplitSeq(rawMerged, []byte{'\n'}) {
				name := strings.TrimSpace(string(line))
				if name != "" {
					mergedSet[name] = true
				}
			}
		}
	}

	const format = "%(refname)%00%(refname:short)%00%(committerdate:short)%00%(committerdate:relative)%00%(authoremail)%00%(authorname)%00%(contents:subject)"
	raw, err := r.OutputRaw("for-each-ref", "--sort=-committerdate", "--format="+format, "refs/heads/", "refs/remotes/origin/")
	if err != nil {
		return nil, err
	}

	var locals []menuBranchEntry
	var remotes []menuBranchEntry
	seenLocal := make(map[string]bool)

	for lineBytes := range bytes.SplitSeq(raw, []byte{'\n'}) {
		if len(lineBytes) == 0 {
			continue
		}
		fields := bytes.SplitN(lineBytes, []byte{0}, 7)
		if len(fields) < 7 {
			continue
		}
		fullRef := string(fields[0])
		shortName := string(fields[1])
		shortDate := string(fields[2])
		relDate := string(fields[3])
		authorEmail := strings.Trim(strings.TrimSpace(string(fields[4])), "<>")
		authorName := string(fields[5])
		subject := string(fields[6])

		if shortName == "" || strings.HasSuffix(fullRef, "/HEAD") || shortName == "origin" {
			continue
		}

		isMine := userEmail != "" && strings.EqualFold(authorEmail, userEmail)
		if strings.HasPrefix(fullRef, "refs/heads/") {
			seenLocal[shortName] = true
			isDefault := defaultBranch != "" && shortName == defaultBranch
			locals = append(locals, menuBranchEntry{
				Name:       shortName,
				Scope:      "local",
				ShortDate:  shortDate,
				RelDate:    relDate,
				AuthorName: authorName,
				Subject:    subject,
				IsCurrent:  currentBranch != "" && shortName == currentBranch,
				IsDefault:  isDefault,
				IsMerged:   !isDefault && mergedSet[shortName],
				IsMine:     isMine,
			})
		} else if strings.HasPrefix(fullRef, "refs/remotes/origin/") {
			localEquiv := strings.TrimPrefix(shortName, "origin/")
			isDefault := defaultBranch != "" && localEquiv == defaultBranch
			remotes = append(remotes, menuBranchEntry{
				Name:       shortName,
				Scope:      "remote",
				ShortDate:  shortDate,
				RelDate:    relDate,
				AuthorName: authorName,
				Subject:    subject,
				IsDefault:  isDefault,
				IsMerged:   !isDefault && mergedSet[shortName],
				IsMine:     isMine,
			})
		}
	}

	var filteredRemotes []menuBranchEntry
	for _, rem := range remotes {
		localEquiv := strings.TrimPrefix(rem.Name, "origin/")
		if seenLocal[localEquiv] {
			continue
		}
		filteredRemotes = append(filteredRemotes, rem)
	}

	branchRank := func(e menuBranchEntry) int {
		switch {
		case e.IsCurrent:
			return 0
		case e.IsDefault && e.Scope == "local":
			return 1
		case e.Scope == "local" && !e.IsMerged && e.IsMine:
			return 2
		case e.Scope == "local" && !e.IsMerged:
			return 3
		case e.Scope == "local":
			return 4
		case !e.IsMerged && e.IsMine:
			return 5
		case !e.IsMerged:
			return 6
		default:
			return 7
		}
	}

	all := append(locals, filteredRemotes...)
	slices.SortStableFunc(all, func(a, b menuBranchEntry) int {
		return branchRank(a) - branchRank(b)
	})
	return all, nil
}

func formatMenuBranchLine(e menuBranchEntry) string {
	var tags []string
	if e.IsCurrent {
		tags = append(tags, "\x1b[1;36mcurrent\x1b[0m")
	}
	if e.IsDefault {
		tags = append(tags, "\x1b[32mdefault\x1b[0m")
	}
	if e.Scope == "remote" {
		tags = append(tags, "\x1b[34mremote\x1b[0m")
	}
	if e.IsMine {
		tags = append(tags, "\x1b[33mmine\x1b[0m")
	}
	if !e.IsDefault && e.IsMerged {
		tags = append(tags, "\x1b[2mmerged\x1b[0m")
	} else if !e.IsDefault {
		tags = append(tags, "\x1b[35munmerged\x1b[0m")
	}

	sanitize := func(s string) string {
		return strings.ReplaceAll(s, "\t", " ")
	}

	metaParts := []string{"[" + strings.Join(tags, ",") + "]"}
	if e.ShortDate != "" {
		metaParts = append(metaParts, fmt.Sprintf("\x1b[36m%s\x1b[0m (%s)", sanitize(e.ShortDate), sanitize(e.RelDate)))
	}
	if e.AuthorName != "" {
		metaParts = append(metaParts, sanitize(e.AuthorName))
	}
	if e.Subject != "" {
		metaParts = append(metaParts, sanitize(e.Subject))
	}
	return fmt.Sprintf("%s\t%s", sanitize(e.Name), strings.Join(metaParts, "  "))
}

func collectMenuTags(r *gitcmd.Runner) ([]menuTagEntry, error) {
	const format = "%(refname:short)%00%(creatordate:short)%00%(creatordate:relative)%00%(contents:subject)"
	raw, err := r.OutputRaw("for-each-ref", "--sort=-creatordate", "--format="+format, "refs/tags/")
	if err != nil {
		return nil, err
	}

	var tags []menuTagEntry
	for lineBytes := range bytes.SplitSeq(raw, []byte{'\n'}) {
		if len(lineBytes) == 0 {
			continue
		}
		fields := bytes.SplitN(lineBytes, []byte{0}, 4)
		if len(fields) < 4 {
			continue
		}
		name := strings.TrimSpace(string(fields[0]))
		if name == "" {
			continue
		}
		tags = append(tags, menuTagEntry{
			Name:      name,
			ShortDate: string(fields[1]),
			RelDate:   string(fields[2]),
			Subject:   string(fields[3]),
		})
	}
	return tags, nil
}

func formatMenuTagLine(t menuTagEntry) string {
	sanitize := func(s string) string {
		return strings.ReplaceAll(s, "\t", " ")
	}
	var metaParts []string
	if t.ShortDate != "" {
		metaParts = append(metaParts, fmt.Sprintf("\x1b[36m%s\x1b[0m (%s)", sanitize(t.ShortDate), sanitize(t.RelDate)))
	}
	if t.Subject != "" {
		metaParts = append(metaParts, sanitize(t.Subject))
	}
	return fmt.Sprintf("%s\t%s", sanitize(t.Name), strings.Join(metaParts, "  "))
}

func menuCommonFzfStyleArgs(borderLabel, header, expectKeys, query string) []string {
	args := commonFzfStyleArgs(borderLabel, header)
	args = append(args,
		"--print-query",
		"--expect="+expectKeys,
	)
	if query != "" {
		args = append(args, "--query", query)
	}
	return args
}

func menuWorktreeFzfArgs(selfExe, query string) []string {
	previewCmd := fmt.Sprintf("%q wt _preview {3}", selfExe)
	header := "ENTER: switch/new | ^A: add | ^D: remove | ^X: actions\n" + menuNavHeader
	expect := menuSwitchKeys + ",ctrl-x,ctrl-a,ctrl-d"
	args := menuCommonFzfStyleArgs("🌴 Worktrees (Ctrl-G)", header, expect, query)
	return append(args,
		"--delimiter=\t",
		"--with-nth=1,2",
		"--accept-nth=3",
		"--preview="+previewCmd,
		"--preview-window=right,60%",
		"--preview-border=line",
	)
}

func menuBranchFzfArgs(selfExe, containerDir, defaultBranch, query string) []string {
	previewCmd := fmt.Sprintf(
		"%s menu _preview-branch %s %s {1}",
		shellQuote(selfExe),
		shellQuote(containerDir),
		shellQuote(defaultBranch),
	)
	header := "ENTER: switch/worktree | ^X: actions | ^/: preview\n" + menuNavHeader
	expect := menuSwitchKeys + ",ctrl-x"
	args := menuCommonFzfStyleArgs("🌿 Branches (Ctrl-G)", header, expect, query)
	return append(args,
		"--ansi",
		"--delimiter=\t",
		"--with-nth=1,2",
		"--accept-nth=1",
		"--preview="+previewCmd,
		"--preview-window=right,60%",
		"--preview-border=line",
	)
}

func menuCommitFzfArgs(selfExe, gitDir, cacheDir, fzfSock, query string, ja bool) []string {
	previewCmd := fmt.Sprintf(
		"%s menu _preview-commit %s %s {2}",
		shellQuote(selfExe),
		shellQuote(gitDir),
		shellQuote(cacheDir),
	)
	toggleJaBind := fmt.Sprintf(
		"alt-j:transform(%s menu _toggle-ja %s)",
		shellQuote(selfExe),
		shellQuote(cacheDir),
	)
	header := "ENTER: detail | ^O: browser | Alt-J: ja | Alt-F: zoom | ^X: actions\n" + menuNavHeader
	expect := menuSwitchKeys + ",ctrl-x"
	args := menuCommonFzfStyleArgs(menuCommitBorderLabel(ja), header, expect, query)
	args = append(args,
		"--ansi",
		"--nth=1,3..",
		"--no-sort",
		"--accept-nth=2",
		"--preview="+previewCmd,
		"--preview-window=right,60%",
		"--preview-border=line",
		"--bind=ctrl-o:execute-silent(gh browse {2})",
		"--bind="+toggleJaBind,
		"--bind=alt-f:change-preview-window(down,80%|)",
	)
	if fzfSock != "" {
		args = append(args, "--listen="+fzfSock)
	}
	return args
}

func menuTagFzfArgs(selfExe, query string) []string {
	previewCmd := fmt.Sprintf("%q menu _preview-tag {1}", selfExe)
	header := "ENTER: detail | ^O: browser | ^X: actions | ^/: preview\n" + menuNavHeader
	expect := menuSwitchKeys + ",ctrl-x"
	args := menuCommonFzfStyleArgs("🏷️ Tags (Ctrl-G)", header, expect, query)
	return append(args,
		"--ansi",
		"--delimiter=\t",
		"--with-nth=1,2",
		"--accept-nth=1",
		"--preview="+previewCmd,
		"--preview-window=right,60%",
		"--preview-border=line",
		"--bind=ctrl-o:execute-silent(gh browse {1})",
	)
}

func menuRepoFzfArgs(query string) []string {
	header := "ENTER: switch repo | ^A: clone | ^X: actions | ^/: preview\n" + menuNavHeader
	expect := menuSwitchKeys + ",ctrl-x,ctrl-a"
	args := menuCommonFzfStyleArgs("📦 Repositories (Ctrl-G)", header, expect, query)
	return append(args,
		// Expects 3-level `<host>/<owner>/<repo>` paths; deeper paths (e.g. GitLab subgroups) are rare here.
		// Splitting `<repo>` with `\t` would add tab gaps in the path and make the boundary with worktree labels unclear.
		"--delimiter=[/\t]",
		"--nth=3,4",
		"--with-nth=1..4",
		"--accept-nth=5..",
		"--tiebreak=begin,index",
		"--preview=eza --group-directories-first --icons=always --color=always --no-user --no-time --no-filesize --no-permissions --sort=modified {5..}",
		"--preview-window=right,60%,~3",
	)
}

func switchOrCheckoutMenuBranch(
	ctx gitcmd.RepoContext,
	rawBranch, workDir, defaultBranch string,
	ui menuInteractiveUI,
	stdout, stderr io.Writer,
) error {
	rawBranch = strings.TrimSpace(rawBranch)
	if rawBranch == "" {
		return nil
	}

	branch := strings.TrimPrefix(rawBranch, "origin/")
	r := gitcmd.NewIsolated(ctx.ContainerDir, stderr, stderr)

	existing, err := gitcmd.ListWorktrees(r)
	if err != nil {
		return err
	}
	for _, wt := range existing {
		if wt.Branch == branch {
			if err := maybeAllowDirenv(wt.Path, existing, false, ui.wtUI.confirmDirenvAllow, stderr); err != nil {
				return err
			}
			fmt.Fprintln(stdout, wt.Path)
			return nil
		}
	}

	if ctx.IsBare && filepath.Base(ctx.CommonDir) == ".git" {
		if strings.HasPrefix(branch, "-") || !r.Ok("check-ref-format", "--branch", branch) {
			return fmt.Errorf("invalid branch name: %q", branch)
		}
		dirName, err := gitcmd.WorktreeDirName(branch)
		if err != nil {
			return err
		}
		targetDir := filepath.Join(ctx.ContainerDir, dirName)
		if _, err := os.Stat(targetDir); err == nil {
			return fmt.Errorf("target worktree path already exists: %s", targetDir)
		} else if !os.IsNotExist(err) {
			return err
		}

		hasLocal := r.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+branch)
		hasOrigin := r.Ok("show-ref", "--verify", "--quiet", "refs/remotes/origin/"+branch)
		if hasLocal || hasOrigin {
			if err := checkoutWorktreeBranch(r, targetDir, branch, hasLocal, hasOrigin, existing, false, ui.wtUI.confirmDirenvAllow, stderr); err != nil {
				return err
			}
			fmt.Fprintf(stderr, "Added worktree: %s (branch %s)\n", targetDir, branch)
			fmt.Fprintln(stdout, targetDir)
			return nil
		}
		return createWorktreeFromUnmatchedQuery(ctx, r, branch, workDir, defaultBranch, ui.wtUI, stdout, stderr)
	}

	topLevel, err := gitcmd.New(workDir, stderr, stderr).Output("rev-parse", "--path-format=absolute", "--show-toplevel")
	if err != nil || topLevel == "" {
		topLevel = ctx.ContainerDir
	}
	wtRunner := gitcmd.NewIsolated(topLevel, stderr, stderr)
	hasLocal := wtRunner.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+branch)
	hasOrigin := wtRunner.Ok("show-ref", "--verify", "--quiet", "refs/remotes/origin/"+branch)
	switch {
	case hasLocal:
		return wtRunner.Stream("switch", branch)
	case hasOrigin:
		return wtRunner.Stream("switch", "--track", "-c", branch, "origin/"+branch)
	default:
		return fmt.Errorf("branch %q does not exist locally or on origin", branch)
	}
}

func runGlobalRepoMaintenanceAction(action, workDir string, ui menuInteractiveUI, stderr io.Writer) (bool, error) {
	switch action {
	case menuActionRefresh:
		return true, ui.runRefresh(workDir, stderr)
	case menuActionDeleteMerged:
		return true, ui.runDeleteMerged(false, workDir, stderr)
	case menuActionDeleteMergedWithPR:
		return true, ui.runDeleteMerged(true, workDir, stderr)
	default:
		return false, nil
	}
}

func handleMenuWorktreesStep(
	selfExe, query, workDir string,
	hasRepo bool,
	ctx gitcmd.RepoContext,
	ui menuInteractiveUI,
	stdout, stderr io.Writer,
) (menuStepResult, error) {
	if !hasRepo {
		fmt.Fprintln(stderr, "Not inside a git repository; switching to repositories view.")
		return menuStepResult{nextMode: menuModeRepos}, nil
	}

	r := gitcmd.NewIsolated(ctx.CommonDir, stderr, stderr)
	wts, err := gitcmd.ListWorktrees(r)
	if err != nil {
		return menuStepResult{done: true}, err
	}
	defaultBranch, _ := gitcmd.DetectDefaultBranch(r, ctx.CommonDir, ctx.IsBare)
	sortWorktrees(wts, ctx.ContainerDir, defaultBranch)

	var listBuf bytes.Buffer
	writeWorktreeList(wts, ctx.ContainerDir, &listBuf)

	choice, err := ui.selectMenuItem(menuModeWorktrees, menuWorktreeFzfArgs(selfExe, query), &listBuf, stderr)
	if err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return menuStepResult{done: true}, nil
		}
		return menuStepResult{done: true}, err
	}

	wt, hasWT := findWorktreeByPath(wts, choice.Path)
	if nextMode, ok := modeFromSwitchKey(choice.Key); ok {
		res := menuStepResult{nextMode: nextMode}
		if nextMode == menuModeCommits && hasWT {
			res.commitDir = wt.Path
		}
		return res, nil
	}

	switch choice.Key {
	case "":
		if hasWT {
			return menuStepResult{done: true}, runSelectAction(actionSwitch, ctx, wt, hasWT, defaultBranch, workDir, ui.wtUI, stdout, stderr)
		}
		return menuStepResult{done: true}, createWorktreeFromUnmatchedQuery(ctx, r, choice.Query, workDir, defaultBranch, ui.wtUI, stdout, stderr)
	case "ctrl-a":
		return menuStepResult{done: true}, runSelectAction(actionAdd, ctx, wt, hasWT, defaultBranch, workDir, ui.wtUI, stdout, stderr)
	case "ctrl-d":
		return menuStepResult{done: true}, runSelectAction(actionRemove, ctx, wt, hasWT, defaultBranch, workDir, ui.wtUI, stdout, stderr)
	case "ctrl-x":
		var options []string
		header := "Repository actions"
		if hasWT {
			label := wtWorktreeLabel(ctx.ContainerDir, wt.Path)
			header = fmt.Sprintf("Action for %s (%s)", label, wt.Branch)
			options = append(options, actionLabelSwitch, actionLabelAdd, actionLabelRemove, menuActionWTCommits)
		} else {
			options = append(options, actionLabelAdd)
		}
		options = append(options, menuActionWTPR, menuActionWTPromote, menuActionRefresh, menuActionDeleteMerged, menuActionDeleteMergedWithPR)

		picked, err := ui.chooseAction(header, options, stderr)
		if err != nil {
			if errors.Is(err, gitcmd.ErrSelectionCanceled) {
				return menuStepResult{done: true}, nil
			}
			return menuStepResult{done: true}, err
		}
		if handled, err := runGlobalRepoMaintenanceAction(picked, workDir, ui, stderr); handled {
			return menuStepResult{done: true}, err
		}
		switch picked {
		case actionLabelSwitch:
			return menuStepResult{done: true}, runSelectAction(actionSwitch, ctx, wt, hasWT, defaultBranch, workDir, ui.wtUI, stdout, stderr)
		case actionLabelAdd:
			return menuStepResult{done: true}, runSelectAction(actionAdd, ctx, wt, hasWT, defaultBranch, workDir, ui.wtUI, stdout, stderr)
		case actionLabelRemove:
			return menuStepResult{done: true}, runSelectAction(actionRemove, ctx, wt, hasWT, defaultBranch, workDir, ui.wtUI, stdout, stderr)
		case menuActionWTCommits:
			return menuStepResult{nextMode: menuModeCommits, commitDir: wt.Path}, nil
		case menuActionWTPR:
			spec, err := ui.inputText("PR number, URL, or branch: ", "123", stderr)
			if err != nil {
				if errors.Is(err, gitcmd.ErrSelectionCanceled) {
					return menuStepResult{done: true}, nil
				}
				return menuStepResult{done: true}, err
			}
			return menuStepResult{done: true}, ui.runWTPR(spec, workDir, stdout, stderr)
		case menuActionWTPromote:
			return menuStepResult{done: true}, ui.runWTPromote(workDir, stdout, stderr)
		default:
			return menuStepResult{done: true}, fmt.Errorf("unexpected action selection: %q", picked)
		}
	default:
		return menuStepResult{done: true}, fmt.Errorf("unexpected fzf key: %q", choice.Key)
	}
}

func handleMenuBranchesStep(
	selfExe, query, workDir string,
	hasRepo bool,
	ctx gitcmd.RepoContext,
	ui menuInteractiveUI,
	stdout, stderr io.Writer,
) (menuStepResult, error) {
	if !hasRepo {
		fmt.Fprintln(stderr, "Not inside a git repository; switching to repositories view.")
		return menuStepResult{nextMode: menuModeRepos}, nil
	}

	r := gitcmd.NewIsolated(ctx.ContainerDir, stderr, stderr)
	defaultBranch, _ := gitcmd.DetectDefaultBranch(r, ctx.CommonDir, ctx.IsBare)
	currentBranch := detectCurrentWorktreeBranch(workDir, stderr)

	entries, err := collectMenuBranches(r, defaultBranch, currentBranch)
	if err != nil {
		return menuStepResult{done: true}, err
	}

	var listBuf bytes.Buffer
	for _, entry := range entries {
		listBuf.WriteString(formatMenuBranchLine(entry))
		listBuf.WriteByte('\n')
	}

	choice, err := ui.selectMenuItem(menuModeBranches, menuBranchFzfArgs(selfExe, ctx.ContainerDir, defaultBranch, query), &listBuf, stderr)
	if err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return menuStepResult{done: true}, nil
		}
		return menuStepResult{done: true}, err
	}

	if nextMode, ok := modeFromSwitchKey(choice.Key); ok {
		return menuStepResult{nextMode: nextMode}, nil
	}

	targetBranch := strings.TrimSpace(choice.Path)
	switch choice.Key {
	case "":
		if targetBranch != "" {
			return menuStepResult{done: true}, switchOrCheckoutMenuBranch(ctx, targetBranch, workDir, defaultBranch, ui, stdout, stderr)
		}
		return menuStepResult{done: true}, createWorktreeFromUnmatchedQuery(ctx, r, choice.Query, workDir, defaultBranch, ui.wtUI, stdout, stderr)
	case "ctrl-x":
		var options []string
		header := "Repository actions"
		if targetBranch != "" {
			header = fmt.Sprintf("Action for branch %s", targetBranch)
			options = append(options, menuActionBranchSwitch, menuActionBranchShow)
		}
		options = append(options, menuActionRefresh, menuActionDeleteMerged, menuActionDeleteMergedWithPR)

		picked, err := ui.chooseAction(header, options, stderr)
		if err != nil {
			if errors.Is(err, gitcmd.ErrSelectionCanceled) {
				return menuStepResult{done: true}, nil
			}
			return menuStepResult{done: true}, err
		}
		if handled, err := runGlobalRepoMaintenanceAction(picked, workDir, ui, stderr); handled {
			return menuStepResult{done: true}, err
		}
		switch picked {
		case menuActionBranchSwitch:
			return menuStepResult{done: true}, switchOrCheckoutMenuBranch(ctx, targetBranch, workDir, defaultBranch, ui, stdout, stderr)
		case menuActionBranchShow:
			return menuStepResult{done: true}, ui.showRevDetail(ctx.ContainerDir, targetBranch, stderr)
		default:
			return menuStepResult{done: true}, fmt.Errorf("unexpected action selection: %q", picked)
		}
	default:
		return menuStepResult{done: true}, fmt.Errorf("unexpected fzf key: %q", choice.Key)
	}
}

func handleMenuCommitsStep(
	selfExe, query, workDir, commitDir string,
	hasRepo bool,
	ctx gitcmd.RepoContext,
	ui menuInteractiveUI,
	stderr io.Writer,
) (menuStepResult, error) {
	if !hasRepo {
		fmt.Fprintln(stderr, "Not inside a git repository; switching to repositories view.")
		return menuStepResult{nextMode: menuModeRepos}, nil
	}

	gitDir := commitDir
	if gitDir == "" {
		gitDir = workDir
	}
	if gitDir == "" {
		// CLI callers pass empty workDir; resolve cwd before falling back to ctx.ContainerDir
		// so linked worktrees show their own HEAD instead of the bare root HEAD.
		if cwd, err := os.Getwd(); err == nil {
			gitDir = cwd
		}
	}
	if gitDir == "" {
		gitDir = ctx.ContainerDir
	}

	cacheDir, err := os.MkdirTemp("", "git-x-menu-commits-*")
	if err != nil {
		return menuStepResult{done: true}, fmt.Errorf("failed to create temp cache dir: %w", err)
	}
	defer os.RemoveAll(cacheDir)

	jaDefault := localeDefaultsToJa()
	if jaDefault {
		if err := setJaEnabled(cacheDir, true); err != nil {
			return menuStepResult{done: true}, fmt.Errorf("failed to enable translation mode: %w", err)
		}
	}

	fzfSock := filepath.Join(cacheDir, "fzf.sock")
	workerCtx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go runCommitTranslationWorker(workerCtx, selfExe, gitDir, cacheDir, fzfSock, stderr)

	fzfArgs := menuCommitFzfArgs(selfExe, gitDir, cacheDir, fzfSock, query, jaDefault)
	choice, err := ui.selectCommitItem(gitDir, fzfArgs, stderr)
	if err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return menuStepResult{done: true}, nil
		}
		return menuStepResult{done: true}, err
	}

	if nextMode, ok := modeFromSwitchKey(choice.Key); ok {
		return menuStepResult{nextMode: nextMode}, nil
	}

	rev := cleanRev(choice.Path)
	switch choice.Key {
	case "":
		if rev == "" {
			return menuStepResult{done: true}, nil
		}
		return menuStepResult{done: true}, ui.showRevDetail(gitDir, rev, stderr)
	case "ctrl-x":
		var options []string
		header := "Repository actions"
		if rev != "" {
			header = fmt.Sprintf("Action for commit %s", rev)
			options = append(options, menuActionCommitDetail, menuActionCommitBrowse, menuActionCommitRevert)
		}
		options = append(options, menuActionRefresh, menuActionDeleteMerged, menuActionDeleteMergedWithPR)

		picked, err := ui.chooseAction(header, options, stderr)
		if err != nil {
			if errors.Is(err, gitcmd.ErrSelectionCanceled) {
				return menuStepResult{done: true}, nil
			}
			return menuStepResult{done: true}, err
		}
		if handled, err := runGlobalRepoMaintenanceAction(picked, workDir, ui, stderr); handled {
			return menuStepResult{done: true}, err
		}
		switch picked {
		case menuActionCommitDetail:
			return menuStepResult{done: true}, ui.showRevDetail(gitDir, rev, stderr)
		case menuActionCommitBrowse:
			return menuStepResult{done: true}, ui.browseRev(gitDir, rev, stderr)
		case menuActionCommitRevert:
			return menuStepResult{done: true}, ui.revertRev(gitDir, rev, stderr)
		default:
			return menuStepResult{done: true}, fmt.Errorf("unexpected action selection: %q", picked)
		}
	default:
		return menuStepResult{done: true}, fmt.Errorf("unexpected fzf key: %q", choice.Key)
	}
}

func handleMenuTagsStep(
	selfExe, query, workDir string,
	hasRepo bool,
	ctx gitcmd.RepoContext,
	ui menuInteractiveUI,
	stderr io.Writer,
) (menuStepResult, error) {
	if !hasRepo {
		fmt.Fprintln(stderr, "Not inside a git repository; switching to repositories view.")
		return menuStepResult{nextMode: menuModeRepos}, nil
	}

	r := gitcmd.NewIsolated(ctx.ContainerDir, stderr, stderr)
	tags, err := collectMenuTags(r)
	if err != nil {
		return menuStepResult{done: true}, err
	}

	var listBuf bytes.Buffer
	for _, t := range tags {
		listBuf.WriteString(formatMenuTagLine(t))
		listBuf.WriteByte('\n')
	}

	choice, err := ui.selectMenuItem(menuModeTags, menuTagFzfArgs(selfExe, query), &listBuf, stderr)
	if err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return menuStepResult{done: true}, nil
		}
		return menuStepResult{done: true}, err
	}

	if nextMode, ok := modeFromSwitchKey(choice.Key); ok {
		return menuStepResult{nextMode: nextMode}, nil
	}

	tag := strings.TrimSpace(choice.Path)
	switch choice.Key {
	case "":
		if tag == "" {
			return menuStepResult{done: true}, nil
		}
		return menuStepResult{done: true}, ui.showRevDetail(ctx.ContainerDir, tag, stderr)
	case "ctrl-x":
		var options []string
		header := "Repository actions"
		if tag != "" {
			header = fmt.Sprintf("Action for tag %s", tag)
			options = append(options, menuActionTagShow, menuActionTagBrowse)
		}
		options = append(options, menuActionRefresh, menuActionDeleteMerged, menuActionDeleteMergedWithPR)

		picked, err := ui.chooseAction(header, options, stderr)
		if err != nil {
			if errors.Is(err, gitcmd.ErrSelectionCanceled) {
				return menuStepResult{done: true}, nil
			}
			return menuStepResult{done: true}, err
		}
		if handled, err := runGlobalRepoMaintenanceAction(picked, workDir, ui, stderr); handled {
			return menuStepResult{done: true}, err
		}
		switch picked {
		case menuActionTagShow:
			return menuStepResult{done: true}, ui.showRevDetail(ctx.ContainerDir, tag, stderr)
		case menuActionTagBrowse:
			return menuStepResult{done: true}, ui.browseRev(ctx.ContainerDir, tag, stderr)
		default:
			return menuStepResult{done: true}, fmt.Errorf("unexpected action selection: %q", picked)
		}
	default:
		return menuStepResult{done: true}, fmt.Errorf("unexpected fzf key: %q", choice.Key)
	}
}

func runRepoCloneAction(ui menuInteractiveUI, stdout, stderr io.Writer) error {
	spec, err := ui.inputText("Repository: ", "OWNER/REPO or URL", stderr)
	if err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return nil
		}
		return err
	}
	return ui.runRepoClone(spec, stdout, stderr)
}

func handleMenuReposStep(
	query, workDir string,
	hasRepo bool,
	ui menuInteractiveUI,
	stdout, stderr io.Writer,
) (menuStepResult, error) {
	entries, err := collectAllWorktrees()
	if err != nil {
		return menuStepResult{done: true}, err
	}

	var listBuf bytes.Buffer
	for _, entry := range entries {
		listBuf.WriteString(entry.formatLine())
		listBuf.WriteByte('\n')
	}

	choice, err := ui.selectMenuItem(menuModeRepos, menuRepoFzfArgs(query), &listBuf, stderr)
	if err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return menuStepResult{done: true}, nil
		}
		return menuStepResult{done: true}, err
	}

	if nextMode, ok := modeFromSwitchKey(choice.Key); ok {
		return menuStepResult{nextMode: nextMode}, nil
	}

	targetPath := strings.TrimSpace(choice.Path)
	switch choice.Key {
	case "":
		if targetPath != "" {
			fmt.Fprintln(stdout, targetPath)
		}
		return menuStepResult{done: true}, nil
	case "ctrl-a":
		return menuStepResult{done: true}, runRepoCloneAction(ui, stdout, stderr)
	case "ctrl-x":
		var options []string
		header := "Repository actions"
		if targetPath != "" {
			header = fmt.Sprintf("Action for %s", targetPath)
			options = append(options, menuActionRepoSwitch)
		}
		options = append(options, menuActionRepoClone)
		actionDir := targetPath
		if actionDir == "" && hasRepo {
			actionDir = workDir
		}
		if actionDir != "" {
			options = append(options, menuActionRefresh, menuActionDeleteMerged, menuActionDeleteMergedWithPR)
		}

		picked, err := ui.chooseAction(header, options, stderr)
		if err != nil {
			if errors.Is(err, gitcmd.ErrSelectionCanceled) {
				return menuStepResult{done: true}, nil
			}
			return menuStepResult{done: true}, err
		}
		if handled, err := runGlobalRepoMaintenanceAction(picked, actionDir, ui, stderr); handled {
			return menuStepResult{done: true}, err
		}
		switch picked {
		case menuActionRepoSwitch:
			if targetPath != "" {
				fmt.Fprintln(stdout, targetPath)
			}
			return menuStepResult{done: true}, nil
		case menuActionRepoClone:
			return menuStepResult{done: true}, runRepoCloneAction(ui, stdout, stderr)
		default:
			return menuStepResult{done: true}, fmt.Errorf("unexpected action selection: %q", picked)
		}
	default:
		return menuStepResult{done: true}, fmt.Errorf("unexpected fzf key: %q", choice.Key)
	}
}

func isInsideWorkTree(workDir string, stderr io.Writer) bool {
	r := gitcmd.New(workDir, stderr, stderr)
	inside, err := r.Output("rev-parse", "--is-inside-work-tree")
	return err == nil && inside == "true"
}

func resolveAutoMenuMode(workDir string, hasRepo bool, stderr io.Writer) menuMode {
	if !hasRepo {
		return menuModeRepos
	}
	if isInsideWorkTree(workDir, stderr) {
		return menuModeCommits
	}
	return menuModeWorktrees
}

func printMenuUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: git x menu [--mode <worktrees|branches|commits|tags|repos>] [<query>]\n\n")
	fmt.Fprintf(w, "Unified interactive fzf/gum launcher for worktrees, branches, commits, tags, and repositories.\n")
	fmt.Fprintf(w, "Switch views inside fzf with Ctrl-W (worktrees), Ctrl-B (branches), Ctrl-L (commits), Ctrl-T (tags), or Ctrl-R (repos).\n")
	fmt.Fprintf(w, "Press Ctrl-X for context and maintenance actions (clone, PR checkout, promote, refresh, delete-merged-branches).\n")
}

func newMenuFlagSet(stderr io.Writer) (*flag.FlagSet, *string) {
	fs := flag.NewFlagSet("git-x menu", flag.ContinueOnError)
	fs.SetOutput(stderr)
	modeFlag := fs.String("mode", "", "initial view: worktrees, branches, commits, tags, or repos")
	fs.Usage = func() {
		printMenuUsage(stderr)
	}
	return fs, modeFlag
}

func runMenuWithUI(args []string, workDir string, ui menuInteractiveUI, stdout, stderr io.Writer) error {
	if len(args) > 0 {
		switch args[0] {
		case "_preview-branch":
			if len(args) < 4 {
				return nil
			}
			return gitcmd.RenderBranchPreview(args[1], args[2], args[3], stdout, stderr)
		case "_preview-tag":
			if len(args) < 2 {
				return nil
			}
			return renderTagPreview(workDir, args[1], stdout, stderr)
		case "_preview-commit":
			if len(args) < 4 {
				return nil
			}
			selfExe, err := os.Executable()
			if err != nil {
				return fmt.Errorf("resolve executable path: %w", err)
			}
			return menuRunCommitPreview(selfExe, args[1], args[2], args[3], stdout, stderr)
		case "_toggle-ja":
			if len(args) < 2 {
				return nil
			}
			return menuRunToggleJa(args[1], stdout)
		}
	}

	ui = ui.withDefaults()

	fs, modeFlag := newMenuFlagSet(stderr)

	if err := fs.Parse(args); err != nil {
		return err
	}

	mode, err := parseMenuMode(*modeFlag)
	if err != nil {
		printMenuUsage(stderr)
		return err
	}

	query := strings.Join(fs.Args(), " ")

	ctx, repoErr := gitcmd.DetectRepoContext(workDir, stderr, stderr)
	hasRepo := repoErr == nil

	if mode == menuModeAuto {
		mode = resolveAutoMenuMode(workDir, hasRepo, stderr)
	}

	selfExe, err := os.Executable()
	if err != nil {
		return fmt.Errorf("resolve executable path: %w", err)
	}

	commitDir := ""
	for {
		var (
			res     menuStepResult
			stepErr error
		)
		switch mode {
		case menuModeWorktrees:
			res, stepErr = handleMenuWorktreesStep(selfExe, query, workDir, hasRepo, ctx, ui, stdout, stderr)
		case menuModeBranches:
			res, stepErr = handleMenuBranchesStep(selfExe, query, workDir, hasRepo, ctx, ui, stdout, stderr)
		case menuModeCommits:
			res, stepErr = handleMenuCommitsStep(selfExe, query, workDir, commitDir, hasRepo, ctx, ui, stderr)
		case menuModeTags:
			res, stepErr = handleMenuTagsStep(selfExe, query, workDir, hasRepo, ctx, ui, stderr)
		case menuModeRepos:
			res, stepErr = handleMenuReposStep(query, workDir, hasRepo, ui, stdout, stderr)
		default:
			return fmt.Errorf("unsupported menu mode: %q", mode)
		}
		if stepErr != nil {
			return stepErr
		}
		if res.done {
			return nil
		}
		// Clear initial query when switching views via keybindings so the new view starts unfiltered.
		query = ""
		mode = res.nextMode
		if mode == menuModeCommits {
			commitDir = res.commitDir
		} else {
			commitDir = ""
		}
	}
}

func runMenu(args []string, workDir string, stdout, stderr io.Writer) error {
	return runMenuWithUI(args, workDir, menuInteractiveUI{}, stdout, stderr)
}

package main

import (
	"bytes"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

func wtWorktreeLabel(containerDir, wtPath string) string {
	cleanContainer := filepath.Clean(containerDir)
	cleanWT := filepath.Clean(wtPath)
	if cleanWT == cleanContainer {
		return "."
	}
	rel, err := filepath.Rel(cleanContainer, cleanWT)
	if err == nil && rel != "." && !strings.HasPrefix(rel, "..") {
		return strings.ReplaceAll(filepath.ToSlash(rel), "/", "-")
	}
	return filepath.Base(cleanWT)
}

func sortWorktrees(wts []gitcmd.Worktree, containerDir, defaultBranch string) {
	sort.SliceStable(wts, func(i, j int) bool {
		iDefault := defaultBranch != "" && wts[i].Branch == defaultBranch
		jDefault := defaultBranch != "" && wts[j].Branch == defaultBranch
		if iDefault != jDefault {
			return iDefault
		}
		iLabel := wtWorktreeLabel(containerDir, wts[i].Path)
		jLabel := wtWorktreeLabel(containerDir, wts[j].Path)
		if (iLabel == ".") != (jLabel == ".") {
			return iLabel == "."
		}
		return iLabel < jLabel
	})
}

func maybeAllowDirenv(
	targetDir string,
	existing []gitcmd.Worktree,
	trust bool,
	confirmFn func(dirName string, stderr io.Writer) (bool, error),
	stderr io.Writer,
) error {
	envrcPath := filepath.Join(targetDir, ".envrc")
	info, err := os.Stat(envrcPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return err
	}
	if info.IsDir() {
		return nil
	}

	if trust {
		return allowDirenv(targetDir, stderr)
	}

	targetBytes, err := os.ReadFile(envrcPath)
	if err != nil {
		return err
	}

	// Only auto-allow when a sibling worktree already has an allowed .envrc with identical content.
	cleanTarget := filepath.Clean(targetDir)
	for _, wt := range existing {
		if filepath.Clean(wt.Path) == cleanTarget {
			continue
		}
		siblingBytes, err := os.ReadFile(filepath.Join(wt.Path, ".envrc"))
		if err != nil || !bytes.Equal(targetBytes, siblingBytes) {
			continue
		}
		if isDirenvAllowed(wt.Path) {
			return allowDirenv(targetDir, stderr)
		}
	}

	if confirmFn == nil || isDirenvAllowed(targetDir) {
		return nil
	}

	allowed, err := confirmFn(filepath.Base(targetDir), stderr)
	if err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return nil
		}
		return err
	}
	if allowed {
		return allowDirenv(targetDir, stderr)
	}
	return nil
}

func writeWorktreeList(wts []gitcmd.Worktree, containerDir string, stdout io.Writer) {
	for _, wt := range wts {
		label := wtWorktreeLabel(containerDir, wt.Path)
		branch := wt.Branch
		if branch == "" {
			if wt.Detached {
				branch = "(detached)"
			} else {
				branch = "(unknown)"
			}
		}
		fmt.Fprintf(stdout, "%s\t%s\t%s\n", label, branch, wt.Path)
	}
}

func wtRunList(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-x wt list", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git x wt list\n\nList worktrees in the current repository.\n")
	}
	if err := fs.Parse(args); err != nil {
		return err
	}
	if len(fs.Args()) != 0 {
		fs.Usage()
		return fmt.Errorf("expected no arguments, got %d", len(fs.Args()))
	}

	ctx, err := gitcmd.DetectRepoContext(workDir, stderr, stderr)
	if err != nil {
		return err
	}
	r := gitcmd.NewIsolated(ctx.CommonDir, stderr, stderr)
	wts, err := gitcmd.ListWorktrees(r)
	if err != nil {
		return err
	}

	defaultBranch, _ := gitcmd.DetectDefaultBranch(r, ctx.CommonDir, ctx.IsBare)
	sortWorktrees(wts, ctx.ContainerDir, defaultBranch)
	writeWorktreeList(wts, ctx.ContainerDir, stdout)
	return nil
}

func wtRunPath(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-x wt path", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git x wt path [<name>]\n\nPrint the path of the named worktree, or the default branch worktree if omitted.\n")
	}
	if err := fs.Parse(args); err != nil {
		return err
	}
	remaining := fs.Args()
	if len(remaining) > 1 {
		fs.Usage()
		return fmt.Errorf("expected at most 1 argument, got %d", len(remaining))
	}

	ctx, err := gitcmd.DetectRepoContext(workDir, stderr, stderr)
	if err != nil {
		return err
	}
	r := gitcmd.NewIsolated(ctx.CommonDir, stderr, stderr)
	wts, err := gitcmd.ListWorktrees(r)
	if err != nil {
		return err
	}

	if len(remaining) == 0 {
		defaultBranch, err := gitcmd.DetectDefaultBranch(r, ctx.CommonDir, ctx.IsBare)
		if err != nil {
			return err
		}
		for _, wt := range wts {
			if wt.Branch == defaultBranch {
				fmt.Fprintln(stdout, wt.Path)
				return nil
			}
		}
		return fmt.Errorf("no worktree found for default branch %q", defaultBranch)
	}

	query := remaining[0]
	sanitized := strings.ReplaceAll(query, "/", "-")
	for _, wt := range wts {
		if wt.Branch == query {
			fmt.Fprintln(stdout, wt.Path)
			return nil
		}
	}
	for _, wt := range wts {
		label := wtWorktreeLabel(ctx.ContainerDir, wt.Path)
		if label == query || label == sanitized {
			fmt.Fprintln(stdout, wt.Path)
			return nil
		}
	}
	return fmt.Errorf("worktree %q not found", query)
}

type wtBranchSelector func(containerDir, defaultBranch string, candidates []gitcmd.BranchCandidate, stderr io.Writer) ([]string, error)

func wtFzfAddArgs(selfExe, containerDir, defaultBranch string) []string {
	return gitcmd.FzfBranchSelectArgs(gitcmd.FzfBranchSelectOptions{
		SelfExe:       selfExe,
		RepoDir:       containerDir,
		DefaultBranch: defaultBranch,
		PreviewArgs:   []string{"wt", "_preview-branch"},
		BorderLabel:   "🌴 Add Worktrees",
		Header:        "TAB: toggle | ENTER: add worktree(s) | ESC: cancel",
	})
}

func wtSelectAddBranchesWithFzf(containerDir, defaultBranch string, candidates []gitcmd.BranchCandidate, stderr io.Writer) ([]string, error) {
	picked, err := gitcmd.SelectBranchesWithFzf(gitcmd.FzfBranchSelectOptions{
		RepoDir:       containerDir,
		DefaultBranch: defaultBranch,
		PreviewArgs:   []string{"wt", "_preview-branch"},
		BorderLabel:   "🌴 Add Worktrees",
		Header:        "TAB: toggle | ENTER: add worktree(s) | ESC: cancel",
	}, candidates, stderr)
	if err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return nil, errors.New("worktree addition canceled")
		}
		return nil, err
	}
	return picked, nil
}

func detectCurrentWorktreeBranch(workDir string, stderr io.Writer) string {
	r := gitcmd.New(workDir, stderr, stderr)
	inside, err := r.Output("rev-parse", "--is-inside-work-tree")
	if err != nil || inside != "true" {
		return ""
	}
	branch, err := r.Output("symbolic-ref", "--short", "HEAD")
	if err != nil {
		return ""
	}
	return branch
}

func wtNormalizeSelectedBranches(picked []string) []string {
	seen := make(map[string]bool, len(picked))
	var result []string
	for _, raw := range picked {
		branch := strings.TrimSpace(raw)
		if branch == "" || seen[branch] {
			continue
		}
		seen[branch] = true
		result = append(result, branch)
	}
	return result
}

func selectOutputWorktreePath(branches []string, targetDirs map[string]string, currentBranch, defaultBranch string) string {
	// Print only one worktree path to stdout even when multiple worktrees are created.
	// This breaks standard Unix multi-line output to fit shell callers like `cd "$(git-x wt add)"`.
	if currentBranch != "" {
		if path, ok := targetDirs[currentBranch]; ok {
			return path
		}
	}
	if defaultBranch != "" {
		if path, ok := targetDirs[defaultBranch]; ok {
			return path
		}
	}
	return targetDirs[branches[0]]
}

func checkoutWorktreeBranch(
	r *gitcmd.Runner,
	targetDir, branch string,
	hasLocal, hasOrigin bool,
	existing []gitcmd.Worktree,
	trust bool,
	confirmFn func(dirName string, stderr io.Writer) (bool, error),
	stderr io.Writer,
) error {
	switch {
	case hasLocal:
		if err := r.Stream("worktree", "add", targetDir, branch); err != nil {
			return err
		}
	case hasOrigin:
		if err := r.Stream("worktree", "add", "--track", "-b", branch, targetDir, "origin/"+branch); err != nil {
			return err
		}
	default:
		return fmt.Errorf("branch %q does not exist locally or on origin", branch)
	}
	return maybeAllowDirenv(targetDir, existing, trust, confirmFn, stderr)
}

func addSingleBranch(branch, baseRef string, trust bool, workDir string, stdout, stderr io.Writer) error {
	if branch == "" || strings.HasPrefix(branch, "-") {
		return fmt.Errorf("invalid branch name: %q", branch)
	}

	ctx, err := gitcmd.DetectRepoContext(workDir, stderr, stderr)
	if err != nil {
		return err
	}
	if !ctx.IsBare || filepath.Base(ctx.CommonDir) != ".git" {
		return errors.New("repository does not use clean-bare layout (<repo>/.git); cannot place flat worktrees inside a non-bare working tree")
	}

	r := gitcmd.NewIsolated(ctx.ContainerDir, stderr, stderr)
	if !r.Ok("check-ref-format", "--branch", branch) {
		return fmt.Errorf("invalid branch name: %q", branch)
	}

	dirName, err := gitcmd.WorktreeDirName(branch)
	if err != nil {
		return err
	}
	targetDir := filepath.Join(ctx.ContainerDir, dirName)

	existing, err := gitcmd.ListWorktrees(r)
	if err != nil {
		return err
	}
	for _, wt := range existing {
		if wt.Branch == branch {
			if err := maybeAllowDirenv(wt.Path, existing, trust, nil, stderr); err != nil {
				return err
			}
			fmt.Fprintln(stdout, wt.Path)
			return nil
		}
	}

	if _, err := os.Stat(targetDir); err == nil {
		return fmt.Errorf("target worktree path already exists: %s", targetDir)
	} else if !os.IsNotExist(err) {
		return err
	}

	hasLocal := r.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+branch)
	hasOrigin := r.Ok("show-ref", "--verify", "--quiet", "refs/remotes/origin/"+branch)

	switch {
	case baseRef != "":
		if hasLocal {
			return fmt.Errorf("branch %q already exists locally; omit --base to check it out", branch)
		}
		if !r.Ok("rev-parse", "--verify", "--quiet", baseRef+"^{commit}") {
			return fmt.Errorf("base ref %q does not resolve to a commit", baseRef)
		}
		if err := r.Stream("worktree", "add", "--no-track", "-b", branch, targetDir, baseRef); err != nil {
			return err
		}
		if err := maybeAllowDirenv(targetDir, existing, trust, nil, stderr); err != nil {
			return err
		}
	case hasLocal || hasOrigin:
		if err := checkoutWorktreeBranch(r, targetDir, branch, hasLocal, hasOrigin, existing, trust, nil, stderr); err != nil {
			return err
		}
	default:
		defaultBranch, err := gitcmd.DetectDefaultBranch(r, ctx.CommonDir, ctx.IsBare)
		if err != nil {
			return err
		}
		var resolvedBase string
		switch {
		case r.Ok("show-ref", "--verify", "--quiet", "refs/remotes/origin/"+defaultBranch):
			resolvedBase = "origin/" + defaultBranch
		case r.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+defaultBranch):
			resolvedBase = defaultBranch
		case r.Ok("rev-parse", "--verify", "--quiet", "HEAD^{commit}"):
			resolvedBase = "HEAD"
		default:
			return errors.New("repository has no commits to base a new branch on")
		}
		if err := r.Stream("worktree", "add", "--no-track", "-b", branch, targetDir, resolvedBase); err != nil {
			return err
		}
		if err := maybeAllowDirenv(targetDir, existing, trust, nil, stderr); err != nil {
			return err
		}
	}

	fmt.Fprintln(stdout, targetDir)
	return nil
}

func validateNewBranchTarget(
	r *gitcmd.Runner,
	containerDir, branch string,
	existing []gitcmd.Worktree,
) (string, error) {
	if branch == "" || strings.HasPrefix(branch, "-") || !r.Ok("check-ref-format", "--branch", branch) {
		return "", fmt.Errorf("invalid branch name: %q", branch)
	}
	for _, wt := range existing {
		if wt.Branch == branch {
			return "", fmt.Errorf("branch %q is already checked out at %s", branch, wt.Path)
		}
	}
	if r.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+branch) {
		return "", fmt.Errorf("branch %q already exists locally", branch)
	}

	dirName, err := gitcmd.WorktreeDirName(branch)
	if err != nil {
		return "", err
	}
	targetDir := filepath.Join(containerDir, dirName)
	if _, err := os.Stat(targetDir); err == nil {
		return "", fmt.Errorf("target worktree path already exists: %s", targetDir)
	} else if !os.IsNotExist(err) {
		return "", err
	}
	return targetDir, nil
}

func addExistingBranchesInteractive(
	ctx gitcmd.RepoContext,
	r *gitcmd.Runner,
	defaultBranch, currentBranch string,
	candidates []gitcmd.BranchCandidate,
	trust bool,
	ui wtInteractiveUI,
	stdout, stderr io.Writer,
) error {
	picked, err := ui.selectExistingBranches(ctx.ContainerDir, defaultBranch, candidates, stderr)
	if err != nil {
		return err
	}

	selected := wtNormalizeSelectedBranches(picked)
	if len(selected) == 0 {
		return errors.New("no branches selected")
	}

	targetDirs, err := gitcmd.ValidateTargetWorktreeDirs(ctx.ContainerDir, selected)
	if err != nil {
		return err
	}

	existing, err := gitcmd.ListWorktrees(r)
	if err != nil {
		return err
	}
	checkedOut := make(map[string]string, len(existing))
	for _, wt := range existing {
		if wt.Branch != "" {
			checkedOut[wt.Branch] = wt.Path
		}
	}

	for _, branch := range selected {
		if strings.HasPrefix(branch, "-") || !r.Ok("check-ref-format", "--branch", branch) {
			return fmt.Errorf("invalid branch name: %q", branch)
		}
		if wtPath, ok := checkedOut[branch]; ok {
			return fmt.Errorf("branch %q is already checked out at %s", branch, wtPath)
		}
		if !r.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+branch) {
			return fmt.Errorf("selected branch %q does not exist locally", branch)
		}
		targetDir := targetDirs[branch]
		if _, err := os.Stat(targetDir); err == nil {
			return fmt.Errorf("target worktree path already exists: %s", targetDir)
		} else if !os.IsNotExist(err) {
			return err
		}
	}

	for _, branch := range selected {
		targetDir := targetDirs[branch]
		if err := r.Stream("worktree", "add", targetDir, branch); err != nil {
			return err
		}
		if err := maybeAllowDirenv(targetDir, existing, trust, ui.confirmDirenvAllow, stderr); err != nil {
			return err
		}
		fmt.Fprintf(stderr, "Added worktree: %s (branch %s)\n", targetDir, branch)
	}

	fmt.Fprintln(stdout, selectOutputWorktreePath(selected, targetDirs, currentBranch, defaultBranch))
	return nil
}

func addNewBranchFromBaseUI(
	ctx gitcmd.RepoContext,
	r *gitcmd.Runner,
	branch, targetDir, defaultBranch, currentBranch string,
	existing []gitcmd.Worktree,
	trust bool,
	ui wtInteractiveUI,
	stdout, stderr io.Writer,
) error {
	baseOptions := collectBaseRefOptions(r, defaultBranch, currentBranch)
	baseRef, err := ui.chooseBaseRef(branch, baseOptions, ctx.ContainerDir, stderr)
	if err != nil {
		return err
	}
	baseRef = strings.TrimSpace(baseRef)
	if baseRef == "" {
		return gitcmd.ErrSelectionCanceled
	}
	if !r.Ok("rev-parse", "--verify", "--quiet", baseRef+"^{commit}") {
		return fmt.Errorf("base ref %q does not resolve to a commit", baseRef)
	}

	if err := r.Stream("worktree", "add", "--no-track", "-b", branch, targetDir, baseRef); err != nil {
		return err
	}
	if err := maybeAllowDirenv(targetDir, existing, trust, ui.confirmDirenvAllow, stderr); err != nil {
		return err
	}
	fmt.Fprintf(stderr, "Added worktree: %s (branch %s from %s)\n", targetDir, branch, baseRef)
	fmt.Fprintln(stdout, targetDir)
	return nil
}

func addNewBranchInteractive(
	ctx gitcmd.RepoContext,
	r *gitcmd.Runner,
	defaultBranch, currentBranch string,
	trust bool,
	ui wtInteractiveUI,
	stdout, stderr io.Writer,
) error {
	if !r.Ok("rev-parse", "--verify", "--quiet", "HEAD^{commit}") {
		return errors.New("repository has no commits to base a new branch on")
	}

	branch, err := ui.inputNewBranch(stderr)
	if err != nil {
		return err
	}
	branch = strings.TrimSpace(branch)

	existing, err := gitcmd.ListWorktrees(r)
	if err != nil {
		return err
	}
	targetDir, err := validateNewBranchTarget(r, ctx.ContainerDir, branch, existing)
	if err != nil {
		return err
	}

	return addNewBranchFromBaseUI(ctx, r, branch, targetDir, defaultBranch, currentBranch, existing, trust, ui, stdout, stderr)
}

func addInteractive(trust bool, workDir string, ui wtInteractiveUI, stdout, stderr io.Writer) error {
	ui = ui.withDefaults()

	ctx, err := gitcmd.DetectRepoContext(workDir, stderr, stderr)
	if err != nil {
		return err
	}
	if !ctx.IsBare || filepath.Base(ctx.CommonDir) != ".git" {
		return errors.New("repository does not use clean-bare layout (<repo>/.git); cannot place flat worktrees inside a non-bare working tree")
	}

	r := gitcmd.NewIsolated(ctx.ContainerDir, stderr, stderr)
	defaultBranch, _ := gitcmd.DetectDefaultBranch(r, ctx.CommonDir, ctx.IsBare)
	currentBranch := detectCurrentWorktreeBranch(workDir, stderr)

	candidates, err := gitcmd.CollectLocalBranchCandidates(r, gitcmd.CandidateOptions{
		DefaultBranch: defaultBranch,
	})
	if err != nil {
		return err
	}

	mode := addModeNew
	if len(candidates) > 0 {
		mode, err = ui.chooseAddMode(stderr)
		if err != nil {
			return err
		}
	}

	if mode == addModeExisting {
		return addExistingBranchesInteractive(ctx, r, defaultBranch, currentBranch, candidates, trust, ui, stdout, stderr)
	}
	return addNewBranchInteractive(ctx, r, defaultBranch, currentBranch, trust, ui, stdout, stderr)
}

type wtAddFlagValues struct {
	branch      *string
	base        *string
	trust       *bool
	interactive *bool
}

func newWTAddFlagSet(stderr io.Writer) (*flag.FlagSet, wtAddFlagValues) {
	fs := flag.NewFlagSet("git-x wt add", flag.ContinueOnError)
	fs.SetOutput(stderr)
	vals := wtAddFlagValues{
		branch:      fs.String("branch", "", "branch name to check out or create"),
		base:        fs.String("base", "", "base ref for creating a new branch"),
		trust:       fs.Bool("trust", false, "run direnv allow if .envrc exists in the target worktree"),
		interactive: fs.Bool("interactive", false, "add worktree(s) interactively via gum and fzf"),
	}

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git x wt add [--branch <branch> [--base <ref>] | --interactive] [--trust]\n\n")
		fmt.Fprintf(stderr, "Create or switch to flat worktree(s) under the repository directory.\n")
		fmt.Fprintf(stderr, "Defaults to --interactive when --branch is omitted.\n\n")
		fs.PrintDefaults()
	}
	return fs, vals
}

func wtRunAddWithUI(args []string, workDir string, ui wtInteractiveUI, stdout, stderr io.Writer) error {
	fs, vals := newWTAddFlagSet(stderr)

	if err := fs.Parse(args); err != nil {
		return err
	}
	if len(fs.Args()) > 0 {
		fs.Usage()
		return errors.New("unexpected positional arguments; use --branch <branch> or --interactive")
	}

	branchSet := false
	fs.Visit(func(f *flag.Flag) {
		if f.Name == "branch" {
			branchSet = true
		}
	})

	if branchSet && *vals.interactive {
		return errors.New("--branch and --interactive cannot be used together")
	}
	if branchSet {
		return addSingleBranch(*vals.branch, *vals.base, *vals.trust, workDir, stdout, stderr)
	}
	if *vals.base != "" {
		return errors.New("--base cannot be used with --interactive")
	}
	if err := addInteractive(*vals.trust, workDir, ui, stdout, stderr); err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return errors.New("worktree addition canceled")
		}
		return err
	}
	return nil
}

func wtRunDefaultBranch(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-x wt default-branch", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git x wt default-branch\n\nPrint the detected default branch name for the current repository.\n")
	}
	if err := fs.Parse(args); err != nil {
		return err
	}
	if len(fs.Args()) != 0 {
		fs.Usage()
		return fmt.Errorf("expected no arguments, got %d", len(fs.Args()))
	}

	ctx, err := gitcmd.DetectRepoContext(workDir, stderr, stderr)
	if err != nil {
		return err
	}
	r := gitcmd.NewIsolated(ctx.CommonDir, stderr, stderr)
	defaultBranch, err := gitcmd.DetectDefaultBranch(r, ctx.CommonDir, ctx.IsBare)
	if err != nil {
		return err
	}
	fmt.Fprintln(stdout, defaultBranch)
	return nil
}

func wtRunPreview(wtPath string, stdout, stderr io.Writer) error {
	if wtPath == "" {
		return nil
	}

	r := gitcmd.NewIsolated(wtPath, stdout, stderr)
	if err := r.Stream("-c", "color.status=always", "status", "--short", "--branch"); err != nil {
		return err
	}

	if !r.Ok("rev-parse", "--verify", "--quiet", "HEAD^{commit}") {
		fmt.Fprintln(stdout, "\n(no commits yet)")
		return nil
	}

	fmt.Fprintln(stdout)
	return r.Stream("log", "--format="+defaultLogFormat, "--date=short", "--color=always", "-n", "40")
}

func wtFzfSelectArgs(selfExe, query string) []string {
	previewCmd := fmt.Sprintf("%q wt _preview {3}", selfExe)
	args := []string{
		"--height=75%",
		"--tmux=90%,70%",
		"--layout=reverse",
		"--min-height=20+",
		"--border",
		"--no-separator",
		"--header-border=horizontal",
		"--border-label-pos=2",
		"--color=label:blue",
		"--border-label=🌴 Worktrees",
		"--delimiter=\t",
		"--with-nth=1,2",
		"--accept-nth=3",
		"--print-query",
		"--expect=ctrl-x,ctrl-a,ctrl-d",
		"--preview=" + previewCmd,
		"--preview-window=right,60%",
		"--preview-border=line",
		"--header=ENTER: switch/new | CTRL-X: actions | CTRL-A: add | CTRL-D: remove | CTRL-L: log | CTRL-/: preview",
		"--bind=ctrl-l:execute(cd {3} && " + shellQuote(selfExe) + " log-fzf)",
		"--bind=ctrl-/:change-preview-window(down,60%|hidden|)",
	}
	if query != "" {
		args = append(args, "--query", query)
	}
	return args
}

func findWorktreeByPath(wts []gitcmd.Worktree, path string) (gitcmd.Worktree, bool) {
	if path == "" {
		return gitcmd.Worktree{}, false
	}
	cleanTarget := filepath.Clean(path)
	for _, wt := range wts {
		if filepath.Clean(wt.Path) == cleanTarget {
			return wt, true
		}
	}
	return gitcmd.Worktree{}, false
}

func runAddFromSelect(workDir string, ui wtInteractiveUI, stdout, stderr io.Writer) error {
	if err := addInteractive(false, workDir, ui, stdout, stderr); err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return nil
		}
		return err
	}
	return nil
}

func runSelectAction(
	action worktreeAction,
	ctx gitcmd.RepoContext,
	wt gitcmd.Worktree,
	hasWT bool,
	defaultBranch, workDir string,
	ui wtInteractiveUI,
	stdout, stderr io.Writer,
) error {
	switch action {
	case actionSwitch:
		if !hasWT {
			return errors.New("no worktree selected")
		}
		fmt.Fprintln(stdout, wt.Path)
		return nil
	case actionAdd:
		return runAddFromSelect(workDir, ui, stdout, stderr)
	case actionRemove:
		if !hasWT {
			return errors.New("no worktree selected")
		}
		label := wtWorktreeLabel(ctx.ContainerDir, wt.Path)
		if err := removeWorktreeSafely(ctx, wt, label, defaultBranch, workDir, ui.confirmRemoveWorktree, stderr); err != nil {
			if errors.Is(err, gitcmd.ErrSelectionCanceled) {
				return nil
			}
			return err
		}
		return nil
	case actionLog:
		if !hasWT {
			return errors.New("no worktree selected")
		}
		return ui.runLogFzf(wt.Path, stderr)
	default:
		return fmt.Errorf("unknown worktree action: %d", action)
	}
}

func createWorktreeFromUnmatchedQuery(
	ctx gitcmd.RepoContext,
	r *gitcmd.Runner,
	query, workDir, defaultBranch string,
	ui wtInteractiveUI,
	stdout, stderr io.Writer,
) error {
	branch := strings.TrimSpace(query)
	if branch == "" {
		return nil
	}

	ok, err := ui.confirmCreateWorktree(branch, stderr)
	if err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return nil
		}
		return err
	}
	if !ok {
		return nil
	}

	if !ctx.IsBare || filepath.Base(ctx.CommonDir) != ".git" {
		return errors.New("repository does not use clean-bare layout (<repo>/.git); cannot place flat worktrees inside a non-bare working tree")
	}
	if strings.HasPrefix(branch, "-") || !r.Ok("check-ref-format", "--branch", branch) {
		return fmt.Errorf("invalid branch name: %q", branch)
	}

	existing, err := gitcmd.ListWorktrees(r)
	if err != nil {
		return err
	}
	for _, wt := range existing {
		if wt.Branch == branch {
			if err := maybeAllowDirenv(wt.Path, existing, false, ui.confirmDirenvAllow, stderr); err != nil {
				return err
			}
			fmt.Fprintln(stdout, wt.Path)
			return nil
		}
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
		if err := checkoutWorktreeBranch(r, targetDir, branch, hasLocal, hasOrigin, existing, false, ui.confirmDirenvAllow, stderr); err != nil {
			return err
		}
		fmt.Fprintf(stderr, "Added worktree: %s (branch %s)\n", targetDir, branch)
		fmt.Fprintln(stdout, targetDir)
		return nil
	}

	if !r.Ok("rev-parse", "--verify", "--quiet", "HEAD^{commit}") {
		return errors.New("repository has no commits to base a new branch on")
	}
	currentBranch := detectCurrentWorktreeBranch(workDir, stderr)
	err = addNewBranchFromBaseUI(ctx, r, branch, targetDir, defaultBranch, currentBranch, existing, false, ui, stdout, stderr)
	if errors.Is(err, gitcmd.ErrSelectionCanceled) {
		return nil
	}
	return err
}

func wtRunSelectWithUI(args []string, workDir string, ui wtInteractiveUI, stdout, stderr io.Writer) error {
	ui = ui.withDefaults()

	fs := flag.NewFlagSet("git-x wt select", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git x wt select [<query>]\n\nSelect a worktree via fzf or run actions via gum, and print the target path.\n")
	}
	if err := fs.Parse(args); err != nil {
		return err
	}
	query := strings.Join(fs.Args(), " ")

	ctx, err := gitcmd.DetectRepoContext(workDir, stderr, stderr)
	if err != nil {
		return err
	}
	r := gitcmd.NewIsolated(ctx.CommonDir, stderr, stderr)
	wts, err := gitcmd.ListWorktrees(r)
	if err != nil {
		return err
	}
	if len(wts) == 0 {
		return nil
	}

	defaultBranch, _ := gitcmd.DetectDefaultBranch(r, ctx.CommonDir, ctx.IsBare)
	sortWorktrees(wts, ctx.ContainerDir, defaultBranch)

	var listBuf bytes.Buffer
	writeWorktreeList(wts, ctx.ContainerDir, &listBuf)

	selfExe, err := os.Executable()
	if err != nil {
		return fmt.Errorf("resolve executable path: %w", err)
	}

	choice, err := ui.selectWorktree(selfExe, query, &listBuf, stderr)
	if err != nil {
		if errors.Is(err, gitcmd.ErrSelectionCanceled) {
			return nil
		}
		return err
	}

	wt, hasWT := findWorktreeByPath(wts, choice.Path)
	switch choice.Key {
	case "":
		if hasWT {
			return runSelectAction(actionSwitch, ctx, wt, hasWT, defaultBranch, workDir, ui, stdout, stderr)
		}
		return createWorktreeFromUnmatchedQuery(ctx, r, choice.Query, workDir, defaultBranch, ui, stdout, stderr)
	case "ctrl-a":
		return runSelectAction(actionAdd, ctx, wt, hasWT, defaultBranch, workDir, ui, stdout, stderr)
	case "ctrl-d":
		return runSelectAction(actionRemove, ctx, wt, hasWT, defaultBranch, workDir, ui, stdout, stderr)
	case "ctrl-x":
		if !hasWT {
			return runSelectAction(actionAdd, ctx, wt, hasWT, defaultBranch, workDir, ui, stdout, stderr)
		}
		label := wtWorktreeLabel(ctx.ContainerDir, wt.Path)
		action, err := ui.chooseWorktreeAction(label, wt.Branch, stderr)
		if err != nil {
			if errors.Is(err, gitcmd.ErrSelectionCanceled) {
				return nil
			}
			return err
		}
		return runSelectAction(action, ctx, wt, hasWT, defaultBranch, workDir, ui, stdout, stderr)
	default:
		return fmt.Errorf("unexpected fzf key: %q", choice.Key)
	}
}

type wtSubcommand struct {
	name          string
	usage         string
	description   string
	hidden        bool
	outputsTarget bool
	newFlags      func(stderr io.Writer) *flag.FlagSet
	flagValues    map[string][]string
	argKind       argCompletionKind
	argLabel      string
	run           func(args []string, workDir string, ui wtInteractiveUI, stdout, stderr io.Writer) error
}

func allWTSubcommands() []wtSubcommand {
	return []wtSubcommand{
		{
			name:        "list",
			usage:       "list",
			description: "List worktrees (default when omitted)",
			run: func(args []string, workDir string, _ wtInteractiveUI, stdout, stderr io.Writer) error {
				return wtRunList(args, workDir, stdout, stderr)
			},
		},
		{
			name:          "select",
			usage:         "select [<query>]",
			description:   "Select a worktree or run actions via fzf and gum",
			outputsTarget: true,
			run:           wtRunSelectWithUI,
		},
		{
			name:          "add",
			usage:         "add [--branch <branch> [--base <ref>] | --interactive]",
			description:   "Add flat worktree(s) (defaults to --interactive)",
			outputsTarget: true,
			newFlags: func(stderr io.Writer) *flag.FlagSet {
				fs, _ := newWTAddFlagSet(stderr)
				return fs
			},
			run: wtRunAddWithUI,
		},
		{
			name:          "pr",
			usage:         "pr [--repo <OWNER/REPO>] [--trust] <number|url|branch>",
			description:   "Check out a GitHub PR into a flat worktree",
			outputsTarget: true,
			newFlags: func(stderr io.Writer) *flag.FlagSet {
				fs, _, _ := newWTPRFlagSet(stderr)
				return fs
			},
			run: func(args []string, workDir string, _ wtInteractiveUI, stdout, stderr io.Writer) error {
				return wtRunPRWithDeps(args, workDir, wtPRDeps{}, stdout, stderr)
			},
		},
		{
			name:          "promote",
			usage:         "promote [--trust]",
			description:   "Move the current branch into its own flat worktree",
			outputsTarget: true,
			newFlags: func(stderr io.Writer) *flag.FlagSet {
				fs, _ := newWTPromoteFlagSet(stderr)
				return fs
			},
			run: func(args []string, workDir string, _ wtInteractiveUI, stdout, stderr io.Writer) error {
				return wtRunPromote(args, workDir, stdout, stderr)
			},
		},
		{
			name:          "path",
			usage:         "path [<name>]",
			description:   "Print worktree path for <name> or default branch",
			outputsTarget: true,
			run: func(args []string, workDir string, _ wtInteractiveUI, stdout, stderr io.Writer) error {
				return wtRunPath(args, workDir, stdout, stderr)
			},
		},
		{
			name:        "default-branch",
			usage:       "default-branch",
			description: "Print the detected default branch name",
			run: func(args []string, workDir string, _ wtInteractiveUI, stdout, stderr io.Writer) error {
				return wtRunDefaultBranch(args, workDir, stdout, stderr)
			},
		},
		{
			name:   "_cd-helper",
			hidden: true,
			run:    wtRunCdHelperWithUI,
		},
		{
			name:   "_preview",
			hidden: true,
			run: func(args []string, _ string, _ wtInteractiveUI, stdout, stderr io.Writer) error {
				if len(args) < 1 {
					return nil
				}
				return wtRunPreview(args[0], stdout, stderr)
			},
		},
		{
			name:   "_preview-branch",
			hidden: true,
			run: func(args []string, _ string, _ wtInteractiveUI, stdout, stderr io.Writer) error {
				if len(args) < 3 {
					return nil
				}
				return gitcmd.RenderBranchPreview(args[0], args[1], args[2], stdout, stderr)
			},
		},
	}
}

func printCdHelperUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: wt [<query> | add ... | pr ... | promote | path ... | select ...]\n\n")
	fmt.Fprintf(w, "Switch to or create a flat git worktree and print the target directory for shell cd.\n")
	fmt.Fprintf(w, "Non-cd commands like `list` or `default-branch` should be run via `git wt`.\n")
}

func wtRunCdHelperWithUI(args []string, workDir string, ui wtInteractiveUI, stdout, stderr io.Writer) error {
	if len(args) == 0 {
		return wtRunSelectWithUI(nil, workDir, ui, stdout, stderr)
	}

	first := args[0]
	switch first {
	case "-h", "--help", "help":
		printCdHelperUsage(stderr)
		if first == "help" {
			return nil
		}
		return flag.ErrHelp
	}

	for _, cmd := range allWTSubcommands() {
		if cmd.name == first {
			if cmd.outputsTarget {
				return cmd.run(args[1:], workDir, ui, stdout, stderr)
			}
			return fmt.Errorf("%q does not return a cd target; run `git wt %s` instead", first, first)
		}
	}

	if isGitXSubcommandName(first) {
		return fmt.Errorf("%q is a git x subcommand, not a worktree query; run `git x %s` instead (or `wt select %s` to search)", first, first, first)
	}

	return wtRunSelectWithUI(args, workDir, ui, stdout, stderr)
}

func printWTUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: git x wt <subcommand> [options] [args]\n\n")
	fmt.Fprintf(w, "Manage flat git worktrees in clean-bare repositories.\n\n")
	fmt.Fprintf(w, "Subcommands:\n")
	for _, cmd := range allWTSubcommands() {
		if cmd.hidden {
			continue
		}
		fmt.Fprintf(w, "  %-55s%s\n", cmd.usage, cmd.description)
	}
}

func runWTWithUI(args []string, workDir string, ui wtInteractiveUI, stdout, stderr io.Writer) error {
	if len(args) == 0 {
		return wtRunList(nil, workDir, stdout, stderr)
	}

	switch args[0] {
	case "-h", "--help", "help":
		printWTUsage(stderr)
		if args[0] == "help" {
			return nil
		}
		return flag.ErrHelp
	}

	for _, cmd := range allWTSubcommands() {
		if cmd.name == args[0] {
			return cmd.run(args[1:], workDir, ui, stdout, stderr)
		}
	}

	printWTUsage(stderr)
	return fmt.Errorf("unknown subcommand: %s", args[0])
}

func runWTWithOptions(args []string, workDir string, selector wtBranchSelector, stdout, stderr io.Writer) error {
	var ui wtInteractiveUI
	if selector != nil {
		ui = wtInteractiveUI{
			selectExistingBranches: selector,
			chooseAddMode: func(io.Writer) (addMode, error) {
				return addModeExisting, nil
			},
			confirmDirenvAllow: func(string, io.Writer) (bool, error) {
				return false, nil
			},
		}
	}
	return runWTWithUI(args, workDir, ui, stdout, stderr)
}

func runWT(args []string, workDir string, stdout, stderr io.Writer) error {
	return runWTWithUI(args, workDir, wtInteractiveUI{}, stdout, stderr)
}

package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

type addMode int

const (
	addModeExisting addMode = iota
	addModeNew
)

type worktreeAction int

const (
	actionSwitch worktreeAction = iota
	actionAdd
	actionRemove
	actionLog
)

const (
	addOptionExisting  = "Existing local branch(es)"
	addOptionNew       = "New branch"
	otherBaseRefOption = "Other ref (fzf)..."

	actionLabelSwitch = "Switch (cd)"
	actionLabelAdd    = "Add worktree"
	actionLabelRemove = "Remove worktree"
	actionLabelLog    = "Open gitx log-fzf"
)

type selectChoice struct {
	Query string
	Key   string
	Path  string
}

type wtInteractiveUI struct {
	chooseAddMode          func(stderr io.Writer) (addMode, error)
	selectExistingBranches wtBranchSelector
	inputNewBranch         func(stderr io.Writer) (string, error)
	chooseBaseRef          func(branch string, baseOptions []string, containerDir string, stderr io.Writer) (string, error)
	confirmDirenvAllow     func(dirName string, stderr io.Writer) (bool, error)
	confirmCreateWorktree  func(branch string, stderr io.Writer) (bool, error)
	selectWorktree         func(selfExe, query string, listInput io.Reader, stderr io.Writer) (selectChoice, error)
	chooseWorktreeAction   func(label, branch string, stderr io.Writer) (worktreeAction, error)
	confirmRemoveWorktree  func(label, branch string, stderr io.Writer) (bool, error)
	runLogFzf              func(wtPath string, stderr io.Writer) error
}

func (ui wtInteractiveUI) withDefaults() wtInteractiveUI {
	if ui.chooseAddMode == nil {
		ui.chooseAddMode = chooseAddModeWithGum
	}
	if ui.selectExistingBranches == nil {
		ui.selectExistingBranches = wtSelectAddBranchesWithFzf
	}
	if ui.inputNewBranch == nil {
		ui.inputNewBranch = inputNewBranchWithGum
	}
	if ui.chooseBaseRef == nil {
		ui.chooseBaseRef = chooseBaseRefWithUI
	}
	if ui.confirmDirenvAllow == nil {
		ui.confirmDirenvAllow = confirmDirenvAllowWithGum
	}
	if ui.confirmCreateWorktree == nil {
		ui.confirmCreateWorktree = confirmCreateWorktreeWithGum
	}
	if ui.selectWorktree == nil {
		ui.selectWorktree = selectWorktreeWithFzf
	}
	if ui.chooseWorktreeAction == nil {
		ui.chooseWorktreeAction = chooseWorktreeActionWithGum
	}
	if ui.confirmRemoveWorktree == nil {
		ui.confirmRemoveWorktree = confirmRemoveWorktreeWithGum
	}
	if ui.runLogFzf == nil {
		ui.runLogFzf = runLogFzfInWorktree
	}
	return ui
}

func runGumOutput(args []string, stderr io.Writer) (string, error) {
	cmd := exec.Command("gum", args...)
	// Attach os.Stdin so interactive widgets can read keystrokes even when stdout is captured by `$(gitx wt ...)`.
	cmd.Stdin = os.Stdin
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		if isCancelExitError(err) {
			return "", gitcmd.ErrSelectionCanceled
		}
		return "", fmt.Errorf("gum %s failed: %w", args[0], err)
	}
	return strings.TrimSpace(out.String()), nil
}

func runGumConfirm(prompt string, stderr io.Writer) (bool, error) {
	cmd := exec.Command("gum", "confirm", "--default=false", prompt)
	cmd.Stdin = os.Stdin
	cmd.Stdout = stderr
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			switch exitErr.ExitCode() {
			case 1:
				return false, nil
			case 130:
				return false, gitcmd.ErrSelectionCanceled
			}
		}
		return false, fmt.Errorf("gum confirm failed: %w", err)
	}
	return true, nil
}

func chooseAddModeWithGum(stderr io.Writer) (addMode, error) {
	picked, err := runGumOutput([]string{
		"choose",
		"--header=Add worktree",
		addOptionExisting,
		addOptionNew,
	}, stderr)
	if err != nil {
		return addModeExisting, err
	}
	switch picked {
	case addOptionExisting:
		return addModeExisting, nil
	case addOptionNew:
		return addModeNew, nil
	default:
		return addModeExisting, fmt.Errorf("unexpected add mode selection: %q", picked)
	}
}

func inputNewBranchWithGum(stderr io.Writer) (string, error) {
	branch, err := runGumOutput([]string{
		"input",
		"--prompt=Branch name: ",
		"--placeholder=feat/my-topic",
	}, stderr)
	if err != nil {
		return "", err
	}
	if branch == "" {
		return "", gitcmd.ErrSelectionCanceled
	}
	return branch, nil
}

func fzfBaseRefArgs(containerDir string) []string {
	previewCmd := fmt.Sprintf(
		"git -C %s log --format=%s --date=short --color=always -n 30 {1}",
		shellQuote(containerDir),
		shellQuote(defaultLogFormat),
	)
	return []string{
		"--height=75%",
		"--tmux=90%,70%",
		"--layout=reverse",
		"--min-height=20+",
		"--border",
		"--no-separator",
		"--header-border=horizontal",
		"--border-label-pos=2",
		"--color=label:blue",
		"--border-label=🌿 Base Ref",
		"--preview=" + previewCmd,
		"--preview-window=right,60%",
		"--preview-border=line",
		"--header=ENTER: select base ref | ESC: cancel | CTRL-/: toggle preview",
		"--bind=ctrl-/:change-preview-window(down,60%|hidden|)",
	}
}

func selectOtherBaseRefWithFzf(containerDir string, stderr io.Writer) (string, error) {
	r := gitcmd.NewIsolated(containerDir, stderr, stderr)
	rawRefs, err := r.OutputRaw("for-each-ref", "--sort=-committerdate", "--format=%(refname:short)", "refs/heads/", "refs/remotes/", "refs/tags/")
	if err != nil {
		return "", err
	}

	var refs []string
	for line := range strings.SplitSeq(string(rawRefs), "\n") {
		ref := strings.TrimSpace(line)
		if ref == "" || strings.HasSuffix(ref, "/HEAD") {
			continue
		}
		refs = append(refs, ref)
	}
	if len(refs) == 0 {
		return "", errors.New("no base refs found in repository")
	}

	cmd := exec.Command("fzf", fzfBaseRefArgs(containerDir)...)
	cmd.Stdin = strings.NewReader(strings.Join(refs, "\n") + "\n")
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		if isCancelExitError(err) {
			return "", gitcmd.ErrSelectionCanceled
		}
		return "", fmt.Errorf("fzf failed: %w", err)
	}
	picked := strings.TrimSpace(out.String())
	if picked == "" {
		return "", gitcmd.ErrSelectionCanceled
	}
	return picked, nil
}

func chooseBaseRefWithUI(branch string, baseOptions []string, containerDir string, stderr io.Writer) (string, error) {
	args := []string{
		"choose",
		fmt.Sprintf("--header=Base ref for %s", branch),
	}
	args = append(args, baseOptions...)
	args = append(args, otherBaseRefOption)

	picked, err := runGumOutput(args, stderr)
	if err != nil {
		return "", err
	}
	if picked == otherBaseRefOption {
		return selectOtherBaseRefWithFzf(containerDir, stderr)
	}
	return picked, nil
}

func confirmDirenvAllowWithGum(dirName string, stderr io.Writer) (bool, error) {
	return runGumConfirm(fmt.Sprintf("Allow direnv in %s?", dirName), stderr)
}

func confirmCreateWorktreeWithGum(branch string, stderr io.Writer) (bool, error) {
	return runGumConfirm(fmt.Sprintf("Create worktree for %q?", branch), stderr)
}

func confirmRemoveWorktreeWithGum(label, branch string, stderr io.Writer) (bool, error) {
	target := label
	if branch != "" && branch != label {
		target = fmt.Sprintf("%s (%s)", label, branch)
	}
	return runGumConfirm(fmt.Sprintf("Remove worktree %s?", target), stderr)
}

func chooseWorktreeActionWithGum(label, branch string, stderr io.Writer) (worktreeAction, error) {
	header := fmt.Sprintf("Action for %s", label)
	if branch != "" {
		header = fmt.Sprintf("Action for %s (%s)", label, branch)
	}
	picked, err := runGumOutput([]string{
		"choose",
		"--header=" + header,
		actionLabelSwitch,
		actionLabelAdd,
		actionLabelRemove,
		actionLabelLog,
	}, stderr)
	if err != nil {
		return actionSwitch, err
	}
	switch picked {
	case actionLabelSwitch:
		return actionSwitch, nil
	case actionLabelAdd:
		return actionAdd, nil
	case actionLabelRemove:
		return actionRemove, nil
	case actionLabelLog:
		return actionLog, nil
	default:
		return actionSwitch, fmt.Errorf("unexpected action selection: %q", picked)
	}
}

func parseFzfSelectOutput(raw string) selectChoice {
	if raw == "" {
		return selectChoice{}
	}
	lines := strings.Split(raw, "\n")
	choice := selectChoice{
		Query: strings.TrimSpace(lines[0]),
	}
	if len(lines) >= 2 {
		choice.Key = strings.TrimSpace(lines[1])
	}
	if len(lines) >= 3 {
		choice.Path = strings.TrimSpace(lines[2])
	}
	return choice
}

func selectWorktreeWithFzf(selfExe, query string, listInput io.Reader, stderr io.Writer) (selectChoice, error) {
	cmd := exec.Command("fzf", wtFzfSelectArgs(selfExe, query)...)
	cmd.Stdin = listInput
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
				// Exit code 1 means "no match"; keep a non-empty query so select can offer creating a new worktree.
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

func runLogFzfInWorktree(wtPath string, stderr io.Writer) error {
	selfExe, err := os.Executable()
	if err != nil {
		return fmt.Errorf("resolve executable path: %w", err)
	}
	cmd := exec.Command(selfExe, "log-fzf")
	cmd.Dir = wtPath
	cmd.Stdin = os.Stdin
	// Keep stdout clean for shell callers such as `cd "$(gitx wt select)"` by routing child output to stderr.
	cmd.Stdout = stderr
	cmd.Stderr = stderr
	return cmd.Run()
}

func collectBaseRefOptions(r *gitcmd.Runner, defaultBranch, currentBranch string) []string {
	var options []string
	seen := make(map[string]bool)
	addIfValid := func(ref, checkRef string) {
		if ref == "" || seen[ref] {
			return
		}
		if r.Ok("show-ref", "--verify", "--quiet", checkRef) {
			seen[ref] = true
			options = append(options, ref)
		}
	}

	if defaultBranch != "" {
		addIfValid("origin/"+defaultBranch, "refs/remotes/origin/"+defaultBranch)
		addIfValid(defaultBranch, "refs/heads/"+defaultBranch)
	}
	if currentBranch != "" {
		addIfValid(currentBranch, "refs/heads/"+currentBranch)
	}
	if len(options) == 0 && r.Ok("rev-parse", "--verify", "--quiet", "HEAD^{commit}") {
		options = append(options, "HEAD")
	}
	return options
}

func removeWorktreeSafely(
	ctx gitcmd.RepoContext,
	wt gitcmd.Worktree,
	label string,
	workDir string,
	confirmFn func(label, branch string, stderr io.Writer) (bool, error),
	stderr io.Writer,
) error {
	if wt.Path == "" {
		return errors.New("no worktree selected")
	}

	cwd := workDir
	if cwd == "" {
		var err error
		cwd, err = os.Getwd()
		if err != nil {
			return fmt.Errorf("resolve working directory: %w", err)
		}
	}
	if isSameOrInside(resolveRealPath(wt.Path), resolveRealPath(cwd)) {
		return fmt.Errorf("cannot remove current worktree %s", wt.Path)
	}

	ok, err := confirmFn(label, wt.Branch, stderr)
	if err != nil {
		return err
	}
	if !ok {
		return nil
	}

	// Never pass --force so dirty worktrees are not deleted without warning.
	r := gitcmd.NewIsolated(ctx.ContainerDir, stderr, stderr)
	if err := r.Stream("worktree", "remove", wt.Path); err != nil {
		return err
	}
	fmt.Fprintf(stderr, "Removed worktree: %s\n", wt.Path)
	return nil
}

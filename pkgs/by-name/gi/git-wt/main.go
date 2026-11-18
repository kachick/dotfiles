package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

func worktreeLabel(containerDir, wtPath string) string {
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
		iLabel := worktreeLabel(containerDir, wts[i].Path)
		jLabel := worktreeLabel(containerDir, wts[j].Path)
		if (iLabel == ".") != (jLabel == ".") {
			return iLabel == "."
		}
		return iLabel < jLabel
	})
}

func isDirenvAllowed(dir string) bool {
	cmd := exec.Command("direnv", "status", "--json")
	cmd.Dir = dir
	out, err := cmd.Output()
	if err != nil {
		return false
	}
	var parsed struct {
		State struct {
			FoundRC *struct {
				Allowed int `json:"allowed"`
			} `json:"foundRC"`
		} `json:"state"`
	}
	if err := json.Unmarshal(out, &parsed); err != nil {
		return false
	}
	return parsed.State.FoundRC != nil && parsed.State.FoundRC.Allowed == 0
}

func allowDirenv(dir string, stderr io.Writer) error {
	cmd := exec.Command("direnv", "allow", dir)
	cmd.Stdout = stderr
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("direnv allow %s: %w", dir, err)
	}
	return nil
}

func maybeAllowDirenv(targetDir string, existing []gitcmd.Worktree, trust bool, stderr io.Writer) error {
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

	return nil
}

func runList(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-wt list", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git-wt list\n\nList worktrees in the current repository.\n")
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

	for _, wt := range wts {
		label := worktreeLabel(ctx.ContainerDir, wt.Path)
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
	return nil
}

func runPath(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-wt path", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git-wt path [<name>]\n\nPrint the path of the named worktree, or the default branch worktree if omitted.\n")
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
		label := worktreeLabel(ctx.ContainerDir, wt.Path)
		if label == query || label == sanitized {
			fmt.Fprintln(stdout, wt.Path)
			return nil
		}
	}
	return fmt.Errorf("worktree %q not found", query)
}

func runAdd(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-wt add", flag.ContinueOnError)
	fs.SetOutput(stderr)
	baseRef := fs.String("base", "", "base ref for creating a new branch")
	trust := fs.Bool("trust", false, "run direnv allow if .envrc exists in the target worktree")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git-wt add [--base <ref>] [--trust] <branch>\n\n")
		fmt.Fprintf(stderr, "Create or switch to a flat worktree under the repository directory.\n\n")
		fs.PrintDefaults()
	}

	if err := fs.Parse(args); err != nil {
		return err
	}
	remaining := fs.Args()
	if len(remaining) != 1 {
		fs.Usage()
		return fmt.Errorf("expected 1 branch argument, got %d", len(remaining))
	}

	branch := remaining[0]
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

	// Replace "/" so all worktrees stay flat at depth 1 under the repository directory.
	dirName := strings.ReplaceAll(branch, "/", "-")
	if dirName == "" || dirName == "." || dirName == ".." || dirName == ".git" {
		return fmt.Errorf("invalid worktree directory name %q for branch %q", dirName, branch)
	}
	targetDir := filepath.Join(ctx.ContainerDir, dirName)

	existing, err := gitcmd.ListWorktrees(r)
	if err != nil {
		return err
	}
	for _, wt := range existing {
		if wt.Branch == branch {
			if err := maybeAllowDirenv(wt.Path, existing, *trust, stderr); err != nil {
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
	case *baseRef != "":
		if hasLocal {
			return fmt.Errorf("branch %q already exists locally; omit --base to check it out", branch)
		}
		if !r.Ok("rev-parse", "--verify", "--quiet", *baseRef+"^{commit}") {
			return fmt.Errorf("base ref %q does not resolve to a commit", *baseRef)
		}
		if err := r.Stream("worktree", "add", "--no-track", "-b", branch, targetDir, *baseRef); err != nil {
			return err
		}
	case hasLocal:
		if err := r.Stream("worktree", "add", targetDir, branch); err != nil {
			return err
		}
	case hasOrigin:
		if err := r.Stream("worktree", "add", "--track", "-b", branch, targetDir, "origin/"+branch); err != nil {
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
	}

	if err := maybeAllowDirenv(targetDir, existing, *trust, stderr); err != nil {
		return err
	}

	fmt.Fprintln(stdout, targetDir)
	return nil
}

func runDefaultBranch(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-wt default-branch", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git-wt default-branch\n\nPrint the detected default branch name for the current repository.\n")
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

func runPreview(wtPath string, stdout, stderr io.Writer) error {
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
	return r.Stream("log",
		"--format=format:%C(cyan)%ad %C(auto)%h %C(auto)%s %C(auto)%d",
		"--date=short", "--color=always", "-n", "40")
}

func fzfSelectArgs(selfExe, query string) []string {
	previewCmd := fmt.Sprintf("%q _preview {3}", selfExe)
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
		"--preview=" + previewCmd,
		"--preview-window=right,60%",
		"--preview-border=line",
		"--header=CTRL-L (git lf) / CTRL-/ (toggle preview)",
		"--bind=ctrl-l:execute(cd {3} && git-log-fzf)",
		"--bind=ctrl-/:change-preview-window(down,60%|hidden|)",
	}
	if query != "" {
		args = append(args, "--query", query)
	}
	return args
}

func runSelect(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-wt select", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git-wt select [<query>]\n\nSelect a worktree via fzf and print its path.\n")
	}
	if err := fs.Parse(args); err != nil {
		return err
	}
	query := strings.Join(fs.Args(), " ")

	var listBuf bytes.Buffer
	if err := runList(nil, workDir, &listBuf, stderr); err != nil {
		return err
	}
	if listBuf.Len() == 0 {
		return nil
	}

	selfExe, err := os.Executable()
	if err != nil {
		return fmt.Errorf("resolve executable path: %w", err)
	}

	cmd := exec.Command("fzf", fzfSelectArgs(selfExe, query)...)
	cmd.Stdin = &listBuf
	cmd.Stdout = stdout
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		// Exit codes 1 (no match) and 130 (user abort) are normal non-selections in fzf.
		if errors.As(err, &exitErr) && (exitErr.ExitCode() == 1 || exitErr.ExitCode() == 130) {
			return nil
		}
		return fmt.Errorf("fzf failed: %w", err)
	}
	return nil
}

func printUsage(w io.Writer) {
	fmt.Fprintf(w, "Usage: git-wt <subcommand> [options] [args]\n\n")
	fmt.Fprintf(w, "Manage flat git worktrees in clean-bare repositories.\n\n")
	fmt.Fprintf(w, "Subcommands:\n")
	fmt.Fprintf(w, "  list                                      List worktrees (default when omitted)\n")
	fmt.Fprintf(w, "  select [<query>]                          Select a worktree interactively via fzf\n")
	fmt.Fprintf(w, "  add [--base <ref>] [--trust] <branch>     Create or reuse a flat worktree\n")
	fmt.Fprintf(w, "  path [<name>]                             Print worktree path for <name> or default branch\n")
	fmt.Fprintf(w, "  default-branch                            Print the detected default branch name\n")
}

func run(args []string, workDir string, stdout, stderr io.Writer) error {
	if len(args) == 0 {
		return runList(nil, workDir, stdout, stderr)
	}

	switch args[0] {
	case "-h", "--help", "help":
		printUsage(stderr)
		if args[0] == "help" {
			return nil
		}
		return flag.ErrHelp
	case "list":
		return runList(args[1:], workDir, stdout, stderr)
	case "select":
		return runSelect(args[1:], workDir, stdout, stderr)
	case "_preview":
		if len(args) < 2 {
			return nil
		}
		return runPreview(args[1], stdout, stderr)
	case "add":
		return runAdd(args[1:], workDir, stdout, stderr)
	case "path":
		return runPath(args[1:], workDir, stdout, stderr)
	case "default-branch":
		return runDefaultBranch(args[1:], workDir, stdout, stderr)
	default:
		printUsage(stderr)
		return fmt.Errorf("unknown subcommand: %s", args[0])
	}
}

func main() {
	if err := run(os.Args[1:], "", os.Stdout, os.Stderr); err != nil {
		if !errors.Is(err, flag.ErrHelp) {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		}
		os.Exit(1)
	}
}

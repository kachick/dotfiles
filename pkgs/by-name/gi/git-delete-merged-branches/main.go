package main

import (
	"bytes"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
)

type gitRunner struct {
	dir    string
	stdout io.Writer
	stderr io.Writer
}

func (r *gitRunner) output(args ...string) (string, error) {
	cmd := exec.Command("git", args...)
	if r.dir != "" {
		cmd.Dir = r.dir
	}
	out, err := cmd.CombinedOutput()
	trimmed := strings.TrimSpace(string(out))
	if err != nil {
		return trimmed, fmt.Errorf("git %s: %w: %s", strings.Join(args, " "), err, trimmed)
	}
	return trimmed, nil
}

func (r *gitRunner) outputRaw(args ...string) ([]byte, error) {
	cmd := exec.Command("git", args...)
	if r.dir != "" {
		cmd.Dir = r.dir
	}
	var stderrBuf bytes.Buffer
	cmd.Stderr = &stderrBuf
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("git %s: %w: %s", strings.Join(args, " "), err, strings.TrimSpace(stderrBuf.String()))
	}
	return out, nil
}

func (r *gitRunner) ok(args ...string) bool {
	cmd := exec.Command("git", args...)
	if r.dir != "" {
		cmd.Dir = r.dir
	}
	return cmd.Run() == nil
}

func (r *gitRunner) stream(args ...string) error {
	cmd := exec.Command("git", args...)
	if r.dir != "" {
		cmd.Dir = r.dir
	}
	cmd.Stdout = r.stdout
	cmd.Stderr = r.stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("git %s: %w", strings.Join(args, " "), err)
	}
	return nil
}

var protectedBranches = []string{"main", "master", "trunk", "develop", "development"}

func hasBranchOrRemote(r *gitRunner, branch string) bool {
	return r.ok("show-ref", "--verify", "--quiet", "refs/heads/"+branch) ||
		r.ok("show-ref", "--verify", "--quiet", "refs/remotes/origin/"+branch) ||
		r.ok("show-ref", "--verify", "--quiet", "refs/remotes/upstream/"+branch)
}

func detectDefaultBranch(r *gitRunner, commonDir string) string {
	for _, remote := range []string{"origin", "upstream"} {
		if ref, err := r.output("symbolic-ref", "--short", "refs/remotes/"+remote+"/HEAD"); err == nil && ref != "" {
			candidate := strings.TrimPrefix(ref, remote+"/")
			if hasBranchOrRemote(r, candidate) {
				return candidate
			}
		}
	}

	commonRunner := &gitRunner{dir: commonDir, stdout: r.stdout, stderr: r.stderr}
	isBareStr, errBare := commonRunner.output("rev-parse", "--is-bare-repository")
	commonHead, errHead := commonRunner.output("symbolic-ref", "--short", "HEAD")
	// In clean-bare repos, .git/HEAD stays on the cloned default branch; in non-bare repos,
	// .git/HEAD tracks whichever feature branch is checked out, so check standard names first.
	if errBare == nil && isBareStr == "true" && errHead == nil && commonHead != "" && hasBranchOrRemote(r, commonHead) {
		return commonHead
	}

	for _, candidate := range protectedBranches {
		if hasBranchOrRemote(r, candidate) {
			return candidate
		}
	}

	if errHead == nil && commonHead != "" && hasBranchOrRemote(r, commonHead) {
		return commonHead
	}
	return ""
}

func resolveTargetRef(r *gitRunner, defaultBranch string) string {
	for _, ref := range []string{
		"refs/heads/" + defaultBranch,
		"refs/remotes/origin/" + defaultBranch,
		"refs/remotes/upstream/" + defaultBranch,
	} {
		if r.ok("show-ref", "--verify", "--quiet", ref) {
			return ref
		}
	}
	return ""
}

type mergedBranch struct {
	name   string
	wtPath string
}

func listMergedBranches(r *gitRunner, targetRef string) ([]mergedBranch, error) {
	// Specify --sort=refname so global branch.sort config does not change ordering.
	raw, err := r.outputRaw("for-each-ref", "--sort=refname", "--merged="+targetRef, "--format=%(refname:short)%00%(worktreepath)", "refs/heads/")
	if err != nil {
		return nil, err
	}

	var result []mergedBranch
	for lineBytes := range bytes.SplitSeq(raw, []byte{'\n'}) {
		if len(lineBytes) == 0 {
			continue
		}
		branchBytes, wtBytes, ok := bytes.Cut(lineBytes, []byte{0})
		branch := string(branchBytes)
		if branch == "" {
			continue
		}
		var wtPath string
		if ok {
			wtPath = string(wtBytes)
		}
		result = append(result, mergedBranch{name: branch, wtPath: wtPath})
	}
	return result, nil
}

func resolveRealPath(path string) string {
	abs, err := filepath.Abs(path)
	if err != nil {
		return filepath.Clean(path)
	}
	resolved, err := filepath.EvalSymlinks(abs)
	if err != nil {
		return abs
	}
	return resolved
}

func isSameOrInside(parentDir, targetPath string) bool {
	rel, err := filepath.Rel(parentDir, targetPath)
	if err != nil {
		return false
	}
	return rel == "." || (rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator)))
}

func isDir(path string) bool {
	info, err := os.Stat(path)
	return err == nil && info.IsDir()
}

func resolveDeleteRunner(r *gitRunner, commonDir, defaultBranch, defaultWT string) *gitRunner {
	if defaultWT != "" && isDir(defaultWT) {
		return &gitRunner{dir: defaultWT, stdout: r.stdout, stderr: r.stderr}
	}
	commonRunner := &gitRunner{dir: commonDir, stdout: r.stdout, stderr: r.stderr}
	if isBare, err := commonRunner.output("rev-parse", "--is-bare-repository"); err == nil && isBare == "true" {
		if head, err := commonRunner.output("symbolic-ref", "--short", "HEAD"); err == nil && head == defaultBranch {
			return commonRunner
		}
	}
	return r
}

func run(args []string, workDir string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("git-delete-merged-branches", flag.ContinueOnError)
	fs.SetOutput(stderr)
	dryRun := fs.Bool("dry-run", false, "show actions without removing worktrees or deleting branches")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git-delete-merged-branches [--dry-run]\n\n")
		fmt.Fprintf(stderr, "Remove local branches merged into the default branch and their clean linked worktrees.\n\n")
		fs.PrintDefaults()
	}

	if err := fs.Parse(args); err != nil {
		return err
	}
	if len(fs.Args()) != 0 {
		fs.Usage()
		return fmt.Errorf("expected no positional arguments, got %d", len(fs.Args()))
	}

	cwd := workDir
	if cwd == "" {
		var err error
		cwd, err = os.Getwd()
		if err != nil {
			return fmt.Errorf("resolve working directory: %w", err)
		}
	}
	cwdReal := resolveRealPath(cwd)

	r := &gitRunner{dir: cwd, stdout: stdout, stderr: stderr}
	commonDir, err := r.output("rev-parse", "--path-format=absolute", "--git-common-dir")
	if err != nil {
		return errors.New("not inside a git repository")
	}
	commonDir = filepath.Clean(commonDir)

	defaultBranch := detectDefaultBranch(r, commonDir)
	if defaultBranch == "" {
		return nil
	}
	targetRef := resolveTargetRef(r, defaultBranch)
	if targetRef == "" {
		return nil
	}

	if !*dryRun {
		if err := r.stream("worktree", "prune"); err != nil {
			return err
		}
	}

	defaultWT, _ := r.output("for-each-ref", "--format=%(worktreepath)", "refs/heads/"+defaultBranch)
	merged, err := listMergedBranches(r, targetRef)
	if err != nil {
		return err
	}

	deleteRunner := resolveDeleteRunner(r, commonDir, defaultBranch, defaultWT)

	for _, entry := range merged {
		if entry.name == defaultBranch || slices.Contains(protectedBranches, entry.name) {
			continue
		}

		if entry.wtPath != "" && isDir(entry.wtPath) {
			wtReal := resolveRealPath(entry.wtPath)
			if isSameOrInside(wtReal, cwdReal) {
				fmt.Fprintf(stderr, "Skipping merged branch %s (currently inside worktree %s)\n", entry.name, entry.wtPath)
				continue
			}

			if *dryRun {
				fmt.Fprintf(stdout, "[dry-run] git worktree remove %s\n", entry.wtPath)
			} else if err := r.stream("worktree", "remove", entry.wtPath); err != nil {
				// Never pass --force so dirty worktrees or main worktrees stay safe.
				fmt.Fprintf(stderr, "Keeping worktree %s for branch %s\n", entry.wtPath, entry.name)
				continue
			}
		}

		if *dryRun {
			fmt.Fprintf(stdout, "[dry-run] git branch --delete %s\n", entry.name)
			continue
		}
		if err := deleteRunner.stream("branch", "--delete", entry.name); err != nil {
			return err
		}
	}

	if !*dryRun {
		if err := r.stream("worktree", "prune"); err != nil {
			return err
		}
	}
	return nil
}

func main() {
	if err := run(os.Args[1:], "", os.Stdout, os.Stderr); err != nil {
		if !errors.Is(err, flag.ErrHelp) {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		}
		os.Exit(1)
	}
}

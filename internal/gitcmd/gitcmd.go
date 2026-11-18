package gitcmd

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"sync"
)

// ProtectedBranches lists common default branch names checked before falling back to HEAD.
var ProtectedBranches = []string{"main", "master", "trunk", "develop", "development"}

var (
	repoEnvOnce sync.Once
	repoEnvKeys map[string]struct{}
)

// fallbackRepoEnvKeys covers repo-binding variables from `git rev-parse --local-env-vars`
// in case invoking git fails before initialization completes.
var fallbackRepoEnvKeys = []string{
	"GIT_ALTERNATE_OBJECT_DIRECTORIES",
	"GIT_COMMON_DIR",
	"GIT_CONFIG",
	"GIT_DIR",
	"GIT_GRAFT_FILE",
	"GIT_IMPLICIT_WORK_TREE",
	"GIT_INDEX_FILE",
	"GIT_NO_REPLACE_OBJECTS",
	"GIT_OBJECT_DIRECTORY",
	"GIT_PREFIX",
	"GIT_REPLACE_REF_BASE",
	"GIT_SHALLOW_FILE",
	"GIT_WORK_TREE",
}

func loadRepoEnvKeys() map[string]struct{} {
	repoEnvOnce.Do(func() {
		keys := make(map[string]struct{}, len(fallbackRepoEnvKeys))
		out, err := exec.Command("git", "rev-parse", "--local-env-vars").Output()
		if err != nil {
			for _, k := range fallbackRepoEnvKeys {
				keys[k] = struct{}{}
			}
			repoEnvKeys = keys
			return
		}
		for line := range strings.SplitSeq(string(out), "\n") {
			name := strings.TrimSpace(line)
			if name == "" {
				continue
			}
			// Keep CLI `-c` overrides passed by callers (for example `git -c ... <alias>`)
			// while stripping repository and worktree binding variables.
			if name == "GIT_CONFIG_PARAMETERS" || name == "GIT_CONFIG_COUNT" {
				continue
			}
			keys[name] = struct{}{}
		}
		repoEnvKeys = keys
	})
	return repoEnvKeys
}

// IsolatedEnv returns a copy of base without repository-binding Git variables
// such as GIT_DIR or GIT_WORK_TREE so commands run against cmd.Dir cleanly.
func IsolatedEnv(base []string) []string {
	strip := loadRepoEnvKeys()
	filtered := make([]string, 0, len(base))
	for _, entry := range base {
		key, _, ok := strings.Cut(entry, "=")
		if ok {
			if _, drop := strip[key]; drop {
				continue
			}
		}
		filtered = append(filtered, entry)
	}
	return filtered
}

// Runner executes git commands in an optional working directory.
type Runner struct {
	Dir            string
	IsolateRepoEnv bool
	Stdout         io.Writer
	Stderr         io.Writer
}

// New creates a Runner that preserves caller Git environment variables (e.g. GIT_DIR)
// for initial repository discovery from workDir.
func New(dir string, stdout, stderr io.Writer) *Runner {
	return &Runner{
		Dir:    dir,
		Stdout: stdout,
		Stderr: stderr,
	}
}

// NewIsolated creates a Runner that clears inherited repo-binding Git environment variables
// so git resolves the repository strictly from dir.
func NewIsolated(dir string, stdout, stderr io.Writer) *Runner {
	return &Runner{
		Dir:            dir,
		IsolateRepoEnv: true,
		Stdout:         stdout,
		Stderr:         stderr,
	}
}

// InDir returns a new isolated Runner targeting dir while keeping output writers.
func (r *Runner) InDir(dir string) *Runner {
	return NewIsolated(dir, r.Stdout, r.Stderr)
}

// Command builds an exec.Cmd for git with Dir and environment isolation applied.
func (r *Runner) Command(args ...string) *exec.Cmd {
	cmd := exec.Command("git", args...)
	if r.Dir != "" {
		cmd.Dir = r.Dir
	}
	if r.IsolateRepoEnv {
		cmd.Env = IsolatedEnv(os.Environ())
	}
	return cmd
}

// Output runs git and returns trimmed combined output.
func (r *Runner) Output(args ...string) (string, error) {
	cmd := r.Command(args...)
	out, err := cmd.CombinedOutput()
	trimmed := strings.TrimSpace(string(out))
	if err != nil {
		return trimmed, fmt.Errorf("git %s: %w: %s", strings.Join(args, " "), err, trimmed)
	}
	return trimmed, nil
}

// OutputRaw runs git and returns raw stdout bytes, capturing stderr for error context.
func (r *Runner) OutputRaw(args ...string) ([]byte, error) {
	cmd := r.Command(args...)
	var stderrBuf bytes.Buffer
	cmd.Stderr = &stderrBuf
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("git %s: %w: %s", strings.Join(args, " "), err, strings.TrimSpace(stderrBuf.String()))
	}
	return out, nil
}

// Ok reports whether git exits with status 0.
func (r *Runner) Ok(args ...string) bool {
	return r.Command(args...).Run() == nil
}

// Stream runs git while forwarding stdout and stderr to the Runner's configured writers.
func (r *Runner) Stream(args ...string) error {
	cmd := r.Command(args...)
	cmd.Stdout = r.Stdout
	cmd.Stderr = r.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("git %s: %w", strings.Join(args, " "), err)
	}
	return nil
}

// RepoContext describes the resolved Git common directory, container directory, and bareness.
type RepoContext struct {
	CommonDir    string
	ContainerDir string
	IsBare       bool
}

// DetectRepoContext resolves the repository containing workDir.
// Initial discovery respects caller GIT_DIR, then probes commonDir in isolation
// so `!` aliases setting GIT_DIR=.git or worktree GIT_DIR do not break bare detection.
func DetectRepoContext(workDir string, stdout, stderr io.Writer) (RepoContext, error) {
	r := New(workDir, stdout, stderr)
	commonDir, err := r.Output("rev-parse", "--path-format=absolute", "--git-common-dir")
	if err != nil {
		return RepoContext{}, errors.New("not inside a git repository")
	}
	commonDir = filepath.Clean(commonDir)

	commonRunner := NewIsolated(commonDir, stdout, stderr)
	isBareStr, err := commonRunner.Output("rev-parse", "--is-bare-repository")
	if err != nil {
		return RepoContext{}, err
	}

	containerDir := commonDir
	if filepath.Base(commonDir) == ".git" {
		containerDir = filepath.Dir(commonDir)
	}

	return RepoContext{
		CommonDir:    commonDir,
		ContainerDir: containerDir,
		IsBare:       isBareStr == "true",
	}, nil
}

// HasBranchOrRemote reports whether branch exists locally or under origin/upstream remotes.
func HasBranchOrRemote(r *Runner, branch string) bool {
	return r.Ok("show-ref", "--verify", "--quiet", "refs/heads/"+branch) ||
		r.Ok("show-ref", "--verify", "--quiet", "refs/remotes/origin/"+branch) ||
		r.Ok("show-ref", "--verify", "--quiet", "refs/remotes/upstream/"+branch)
}

// DetectDefaultBranch determines the repository's default branch name.
func DetectDefaultBranch(r *Runner, commonDir string, isBare bool) (string, error) {
	commonRunner := r.InDir(commonDir)
	for _, remote := range []string{"origin", "upstream"} {
		if ref, err := commonRunner.Output("symbolic-ref", "--short", "refs/remotes/"+remote+"/HEAD"); err == nil && ref != "" {
			candidate := strings.TrimPrefix(ref, remote+"/")
			if HasBranchOrRemote(commonRunner, candidate) {
				return candidate, nil
			}
		}
	}

	commonHead, err := commonRunner.Output("symbolic-ref", "--short", "HEAD")
	// In clean-bare repos, .git/HEAD stays on the cloned default branch; in non-bare repos,
	// .git/HEAD tracks whichever feature branch is checked out, so check standard names first.
	if isBare && err == nil && commonHead != "" && HasBranchOrRemote(commonRunner, commonHead) {
		return commonHead, nil
	}

	for _, candidate := range ProtectedBranches {
		if HasBranchOrRemote(commonRunner, candidate) {
			return candidate, nil
		}
	}

	if err == nil && commonHead != "" {
		return commonHead, nil
	}
	return "", errors.New("cannot detect default branch")
}

// IsProtectedBranch reports whether branch is a standard protected default branch name.
func IsProtectedBranch(branch string) bool {
	return slices.Contains(ProtectedBranches, branch)
}

// Worktree represents a non-bare, non-prunable git worktree entry.
type Worktree struct {
	Path     string
	Head     string
	Branch   string
	Detached bool
	Bare     bool
	Prunable bool
}

// ListWorktrees parses `git worktree list --porcelain -z` and returns active non-bare worktrees.
func ListWorktrees(r *Runner) ([]Worktree, error) {
	raw, err := r.OutputRaw("worktree", "list", "--porcelain", "-z")
	if err != nil {
		return nil, err
	}

	var result []Worktree
	var cur *Worktree

	flush := func() {
		if cur == nil {
			return
		}
		if !cur.Bare && !cur.Prunable && cur.Path != "" {
			if info, err := os.Stat(cur.Path); err == nil && info.IsDir() {
				result = append(result, *cur)
			}
		}
		cur = nil
	}

	for tokenBytes := range bytes.SplitSeq(raw, []byte{0}) {
		token := string(tokenBytes)
		if token == "" {
			flush()
			continue
		}
		if cur == nil {
			cur = &Worktree{}
		}
		switch {
		case strings.HasPrefix(token, "worktree "):
			cur.Path = filepath.Clean(strings.TrimPrefix(token, "worktree "))
		case strings.HasPrefix(token, "HEAD "):
			cur.Head = strings.TrimPrefix(token, "HEAD ")
		case strings.HasPrefix(token, "branch "):
			ref := strings.TrimPrefix(token, "branch ")
			cur.Branch = strings.TrimPrefix(ref, "refs/heads/")
		case token == "detached":
			cur.Detached = true
		case token == "bare":
			cur.Bare = true
		case token == "prunable" || strings.HasPrefix(token, "prunable "):
			cur.Prunable = true
		}
	}
	flush()

	return result, nil
}

// FindBranchWorktree returns the path of an active non-bare worktree checking out branch, or "".
func FindBranchWorktree(r *Runner, branch string) (string, error) {
	wts, err := ListWorktrees(r)
	if err != nil {
		return "", err
	}
	for _, wt := range wts {
		if wt.Branch == branch {
			return wt.Path, nil
		}
	}
	return "", nil
}

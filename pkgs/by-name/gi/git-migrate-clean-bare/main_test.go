package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

func isolateEnv(t *testing.T) {
	t.Helper()
	home := t.TempDir()
	t.Setenv("HOME", home)
	t.Setenv("XDG_DATA_HOME", filepath.Join(home, "xdg-data"))
	t.Setenv("XDG_CONFIG_HOME", filepath.Join(home, "xdg-config"))
	t.Setenv("XDG_CACHE_HOME", filepath.Join(home, "xdg-cache"))
	t.Setenv("XDG_STATE_HOME", filepath.Join(home, "xdg-state"))
	t.Setenv("DIRENV_CONFIG", filepath.Join(home, "direnv-config"))
	t.Setenv("GIT_CONFIG_GLOBAL", "/dev/null")
	t.Setenv("GIT_CONFIG_SYSTEM", "/dev/null")
	t.Setenv("GIT_TERMINAL_PROMPT", "0")
}

func runGit(t *testing.T, dir string, args ...string) string {
	t.Helper()
	cmd := exec.Command("git", args...)
	cmd.Dir = dir
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("git %s failed: %v: %s", strings.Join(args, " "), err, string(out))
	}
	return strings.TrimSpace(string(out))
}

func runDirenvAllow(t *testing.T, dir string) {
	t.Helper()
	cmd := exec.Command("direnv", "allow", dir)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("direnv allow %s failed: %v: %s", dir, err, string(out))
	}
}

func direnvAllowedState(t *testing.T, dir string) int {
	t.Helper()
	cmd := exec.Command("direnv", "status", "--json")
	cmd.Dir = dir
	out, err := cmd.Output()
	if err != nil {
		t.Fatalf("direnv status --json failed: %v", err)
	}
	var parsed struct {
		State struct {
			FoundRC *struct {
				Allowed int `json:"allowed"`
			} `json:"foundRC"`
		} `json:"state"`
	}
	if err := json.Unmarshal(out, &parsed); err != nil {
		t.Fatalf("parse direnv status json: %v: %s", err, string(out))
	}
	if parsed.State.FoundRC == nil {
		t.Fatalf("expected foundRC in direnv status for %s", dir)
	}
	return parsed.State.FoundRC.Allowed
}

func writeFile(t *testing.T, path, content string) {
	t.Helper()
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		t.Fatalf("mkdir %s: %v", filepath.Dir(path), err)
	}
	if err := os.WriteFile(path, []byte(content), 0o644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}

func readFile(t *testing.T, path string) string {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read %s: %v", path, err)
	}
	return string(data)
}

func setupStandardClone(t *testing.T, defaultBranch string) (remoteDir, repoDir string) {
	t.Helper()
	temp := t.TempDir()
	remoteDir = filepath.Join(temp, "remote.git")
	seedDir := filepath.Join(temp, "seed")

	runGit(t, temp, "init", "--bare", "-b", defaultBranch, remoteDir)
	runGit(t, temp, "init", "-b", defaultBranch, seedDir)
	runGit(t, seedDir, "config", "user.name", "Tester")
	runGit(t, seedDir, "config", "user.email", "tester@example.com")
	writeFile(t, filepath.Join(seedDir, "README.md"), "hello\n")
	writeFile(t, filepath.Join(seedDir, "both.txt"), "v1\n")
	writeFile(t, filepath.Join(seedDir, "to-delete.txt"), "bye\n")
	writeFile(t, filepath.Join(seedDir, defaultBranch, "nested.txt"), "collision\n")
	runGit(t, seedDir, "add", ".")
	runGit(t, seedDir, "commit", "-m", "Initial commit")
	runGit(t, seedDir, "remote", "add", "origin", remoteDir)
	runGit(t, seedDir, "push", "-u", "origin", defaultBranch)

	repoDir = filepath.Join(temp, "local-repo")
	runGit(t, temp, "clone", remoteDir, repoDir)
	runGit(t, repoDir, "config", "user.name", "Tester")
	runGit(t, repoDir, "config", "user.email", "tester@example.com")
	return remoteDir, repoDir
}

func TestRun_MigrateCleanBare(t *testing.T) {
	t.Run("migrates standard repo preserving changes, index, stashes, untracked .env, branch-named dir, and direnv trust", func(t *testing.T) {
		isolateEnv(t)
		_, repoDir := setupStandardClone(t, "main")

		// Add local branch, stash, unstaged change, staged add, staged deletion, untracked .env, and trusted .envrc + stale .direnv.
		runGit(t, repoDir, "branch", "local-topic")

		writeFile(t, filepath.Join(repoDir, "README.md"), "stashed\n")
		runGit(t, repoDir, "stash", "push", "-m", "saved-wip")

		writeFile(t, filepath.Join(repoDir, "README.md"), "unstaged edit\n")
		writeFile(t, filepath.Join(repoDir, "both.txt"), "v2-staged\n")
		runGit(t, repoDir, "add", "both.txt")
		writeFile(t, filepath.Join(repoDir, "both.txt"), "v3-unstaged\n")
		writeFile(t, filepath.Join(repoDir, "staged-new.txt"), "staged new\n")
		runGit(t, repoDir, "add", "staged-new.txt")
		runGit(t, repoDir, "rm", "to-delete.txt")
		writeFile(t, filepath.Join(repoDir, ".env"), "SECRET=local\n")
		writeFile(t, filepath.Join(repoDir, ".envrc"), "export TEST_ENV=1\n")
		writeFile(t, filepath.Join(repoDir, ".direnv", "cache"), "stale\n")
		runDirenvAllow(t, repoDir)

		// Verify --dry-run inspects cleanly without modifying the repository.
		var stdout, stderr bytes.Buffer
		if err := run([]string{"--dry-run", repoDir}, "", &stdout, &stderr); err != nil {
			t.Fatalf("dry-run failed: %v, stderr: %s", err, stderr.String())
		}
		if !strings.Contains(stdout.String(), "[dry-run]") {
			t.Errorf("expected [dry-run] output, got: %s", stdout.String())
		}
		if got := runGit(t, repoDir, "rev-parse", "--is-bare-repository"); got != "false" {
			t.Fatalf("dry-run modified bare state: %s", got)
		}
		if got := readFile(t, filepath.Join(repoDir, "main", "nested.txt")); got != "collision\n" {
			t.Fatalf("dry-run modified working tree: %q", got)
		}

		// Execute real migration.
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{repoDir}, "", &stdout, &stderr); err != nil {
			t.Fatalf("migrate failed: %v, stderr: %s", err, stderr.String())
		}

		wantWT := filepath.Join(repoDir, "main")
		if got := strings.TrimSpace(stdout.String()); got != wantWT {
			t.Fatalf("stdout = %q, want %q", got, wantWT)
		}

		if got := runGit(t, repoDir, "rev-parse", "--is-bare-repository"); got != "true" {
			t.Errorf("bare = %q, want true", got)
		}
		if got := runGit(t, repoDir, "config", "--get", "remote.origin.fetch"); got != "+refs/heads/*:refs/remotes/origin/*" {
			t.Errorf("remote.origin.fetch = %q", got)
		}
		if got := runGit(t, wantWT, "symbolic-ref", "--short", "HEAD"); got != "main" {
			t.Errorf("worktree branch = %q, want main", got)
		}

		// Verify collision directory named "main" moved intact inside <repo>/main/main/.
		if got := readFile(t, filepath.Join(wantWT, "main", "nested.txt")); got != "collision\n" {
			t.Errorf("collision file = %q, want collision\\n", got)
		}

		// Verify unstaged, staged, untracked, stash, and local branch preservation.
		if got := readFile(t, filepath.Join(wantWT, "README.md")); got != "unstaged edit\n" {
			t.Errorf("README.md = %q, want unstaged edit\\n", got)
		}
		if got := readFile(t, filepath.Join(wantWT, ".env")); got != "SECRET=local\n" {
			t.Errorf(".env = %q, want SECRET=local\\n", got)
		}
		cachedDiff := runGit(t, wantWT, "diff", "--cached", "--name-status")
		if !strings.Contains(cachedDiff, "A\tstaged-new.txt") || !strings.Contains(cachedDiff, "D\tto-delete.txt") || !strings.Contains(cachedDiff, "M\tboth.txt") {
			t.Errorf("unexpected staged index state:\n%s", cachedDiff)
		}
		unstagedDiff := runGit(t, wantWT, "diff", "--name-only")
		if unstagedDiff != "README.md\nboth.txt" {
			t.Errorf("unstaged diff = %q, want README.md\\nboth.txt", unstagedDiff)
		}
		if got := runGit(t, wantWT, "show", ":both.txt"); got != "v2-staged" {
			t.Errorf("staged :both.txt = %q, want v2-staged", got)
		}
		if got := readFile(t, filepath.Join(wantWT, "both.txt")); got != "v3-unstaged\n" {
			t.Errorf("working tree both.txt = %q, want v3-unstaged\\n", got)
		}
		if stashOut := runGit(t, wantWT, "stash", "list"); !strings.Contains(stashOut, "saved-wip") {
			t.Errorf("stash missing: %q", stashOut)
		}
		if !strings.Contains(runGit(t, wantWT, "for-each-ref", "--format=%(refname:short)", "refs/heads/"), "local-topic") {
			t.Errorf("local-topic branch missing")
		}

		// Stale .direnv cache must be removed, and .envrc must be re-allowed in the new worktree path.
		if _, err := os.Stat(filepath.Join(wantWT, ".direnv")); !os.IsNotExist(err) {
			t.Errorf("expected stale .direnv directory to be removed")
		}
		if state := direnvAllowedState(t, wantWT); state != 0 {
			t.Errorf("expected migrated .envrc to remain allowed, got state=%d", state)
		}

		// Idempotency: running again on repoDir (with arg and via cwd) succeeds with zero mutations.
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{repoDir}, "", &stdout, &stderr); err != nil {
			t.Fatalf("idempotent re-run with arg failed: %v, stderr: %s", err, stderr.String())
		}
		stdout.Reset()
		stderr.Reset()
		if err := run(nil, repoDir, &stdout, &stderr); err != nil {
			t.Fatalf("idempotent re-run from container cwd failed: %v, stderr: %s", err, stderr.String())
		}
	})

	t.Run("migrates repo on non-main default branch and feature branch with slash while preserving linked worktrees", func(t *testing.T) {
		isolateEnv(t)
		_, repoDir := setupStandardClone(t, "trunk")

		// Create an external pre-existing linked worktree and switch main repo to feat/wip.
		extWT := filepath.Join(t.TempDir(), "external-wt")
		runGit(t, repoDir, "worktree", "add", "-b", "other-branch", extWT, "trunk")
		runGit(t, repoDir, "checkout", "-b", "feat/wip")
		writeFile(t, filepath.Join(repoDir, "wip.txt"), "wip\n")

		// Run without positional arg from inside a subdirectory of repoDir.
		subDir := filepath.Join(repoDir, "trunk")
		var stdout, stderr bytes.Buffer
		if err := run(nil, subDir, &stdout, &stderr); err != nil {
			t.Fatalf("migrate from subdir failed: %v, stderr: %s", err, stderr.String())
		}

		wantWT := filepath.Join(repoDir, "feat-wip")
		if got := strings.TrimSpace(stdout.String()); got != wantWT {
			t.Fatalf("stdout = %q, want %q", got, wantWT)
		}
		if got := runGit(t, wantWT, "symbolic-ref", "--short", "HEAD"); got != "feat/wip" {
			t.Errorf("worktree branch = %q, want feat/wip", got)
		}
		if got := readFile(t, filepath.Join(wantWT, "wip.txt")); got != "wip\n" {
			t.Errorf("wip.txt = %q, want wip\\n", got)
		}

		// Bare .git/HEAD should reflect default branch trunk so tools like ghqf detect trunk.
		if got := runGit(t, repoDir, "symbolic-ref", "--short", "HEAD"); got != "trunk" {
			t.Errorf("bare HEAD = %q, want trunk", got)
		}

		// External linked worktree remains intact and functional.
		if got := runGit(t, extWT, "symbolic-ref", "--short", "HEAD"); got != "other-branch" {
			t.Errorf("external worktree branch = %q, want other-branch", got)
		}
		wtList := runGit(t, repoDir, "worktree", "list")
		if !strings.Contains(wtList, wantWT) || !strings.Contains(wtList, extWT) {
			t.Errorf("worktree list missing expected entries:\n%s", wtList)
		}
	})

	t.Run("does not allow untrusted .envrc even if .direnv exists unless --trust is passed", func(t *testing.T) {
		isolateEnv(t)
		_, repoDir := setupStandardClone(t, "main")

		writeFile(t, filepath.Join(repoDir, ".envrc"), "export UNTRUSTED=1\n")
		writeFile(t, filepath.Join(repoDir, ".direnv", "stale"), "x\n")

		var stdout, stderr bytes.Buffer
		if err := run([]string{repoDir}, "", &stdout, &stderr); err != nil {
			t.Fatalf("migrate untrusted failed: %v, stderr: %s", err, stderr.String())
		}
		wtDir := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, wtDir); state == 0 {
			t.Fatalf("expected untrusted .envrc NOT to be allowed, got state=%d", state)
		}

		// With --trust on a fresh repo, .envrc is allowed.
		_, trustedRepo := setupStandardClone(t, "main")
		writeFile(t, filepath.Join(trustedRepo, ".envrc"), "export TRUSTED=1\n")
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"--trust", trustedRepo}, "", &stdout, &stderr); err != nil {
			t.Fatalf("migrate --trust failed: %v, stderr: %s", err, stderr.String())
		}
		trustedWT := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, trustedWT); state != 0 {
			t.Fatalf("expected .envrc to be allowed with --trust, got state=%d", state)
		}
	})

	t.Run("fails closed on detached HEAD, linked worktrees, and in-progress merges", func(t *testing.T) {
		isolateEnv(t)
		_, repoDir := setupStandardClone(t, "main")

		// 1. Detached HEAD
		runGit(t, repoDir, "checkout", "--detach", "HEAD")
		var stdout, stderr bytes.Buffer
		if err := run([]string{repoDir}, "", &stdout, &stderr); err == nil {
			t.Fatal("expected error for detached HEAD, got nil")
		}
		if got := runGit(t, repoDir, "rev-parse", "--is-bare-repository"); got != "false" {
			t.Errorf("repo became bare after detached HEAD failure")
		}

		// Switch back to main for subsequent checks.
		runGit(t, repoDir, "checkout", "main")

		// 2. Linked worktree target (.git is a file)
		linkedWT := filepath.Join(t.TempDir(), "linked")
		runGit(t, repoDir, "worktree", "add", "-b", "linked-br", linkedWT, "main")
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{linkedWT}, "", &stdout, &stderr); err == nil {
			t.Fatal("expected error when targeting a linked worktree, got nil")
		}

		// 3. In-progress merge (MERGE_HEAD present)
		headRev := runGit(t, repoDir, "rev-parse", "HEAD")
		writeFile(t, filepath.Join(repoDir, ".git", "MERGE_HEAD"), headRev+"\n")
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{repoDir}, "", &stdout, &stderr); err == nil {
			t.Fatal("expected error when MERGE_HEAD exists, got nil")
		}
	})

	t.Run("migrates empty repository with unborn HEAD", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		repoDir := filepath.Join(temp, "empty")
		runGit(t, temp, "init", "-b", "trunk", repoDir)
		writeFile(t, filepath.Join(repoDir, ".env"), "LOCAL=1\n")

		var stdout, stderr bytes.Buffer
		if err := run([]string{repoDir}, "", &stdout, &stderr); err != nil {
			t.Fatalf("migrate empty repo failed: %v, stderr: %s", err, stderr.String())
		}
		wantWT := filepath.Join(repoDir, "trunk")
		if got := strings.TrimSpace(stdout.String()); got != wantWT {
			t.Fatalf("stdout = %q, want %q", got, wantWT)
		}
		if got := runGit(t, wantWT, "symbolic-ref", "--short", "HEAD"); got != "trunk" {
			t.Errorf("branch = %q, want trunk", got)
		}
		if got := readFile(t, filepath.Join(wantWT, ".env")); got != "LOCAL=1\n" {
			t.Errorf(".env = %q, want LOCAL=1\\n", got)
		}
	})
}

func TestRun_InteractiveMigration(t *testing.T) {
	t.Run("collects, sorts, formats candidates for fzf and renders preview", func(t *testing.T) {
		isolateEnv(t)
		_, repoDir := setupStandardClone(t, "main")

		// Merged branch (by current user)
		runGit(t, repoDir, "checkout", "-b", "merged-mine")
		writeFile(t, filepath.Join(repoDir, "merged.txt"), "m\n")
		runGit(t, repoDir, "add", "merged.txt")
		runGit(t, repoDir, "commit", "-m", "Merged topic")
		runGit(t, repoDir, "checkout", "main")
		runGit(t, repoDir, "merge", "--no-ff", "merged-mine", "-m", "Merge merged-mine")

		// Unmerged branch by someone else
		runGit(t, repoDir, "checkout", "-b", "other-unmerged", "main")
		writeFile(t, filepath.Join(repoDir, "other.txt"), "o\n")
		runGit(t, repoDir, "add", "other.txt")
		runGit(t, repoDir, "-c", "user.name=Other", "-c", "user.email=other@example.com", "commit", "-m", "Other work")

		// Unmerged branch by current user
		runGit(t, repoDir, "checkout", "-b", "mine-unmerged", "main")
		writeFile(t, filepath.Join(repoDir, "mine.txt"), "mi\n")
		runGit(t, repoDir, "add", "mine.txt")
		runGit(t, repoDir, "commit", "-m", "My topic work")

		// External linked worktree branch (must be excluded from migration candidates)
		extWT := filepath.Join(t.TempDir(), "ext-wt")
		runGit(t, repoDir, "worktree", "add", "-b", "linked-wt", extWT, "main")

		// Switch to current feature branch
		runGit(t, repoDir, "checkout", "-b", "feat/current", "main")
		writeFile(t, filepath.Join(repoDir, "cur.txt"), "c\n")
		runGit(t, repoDir, "add", "cur.txt")
		runGit(t, repoDir, "commit", "-m", "Current wip")

		var stderr bytes.Buffer
		r := gitcmd.NewIsolated(repoDir, &stderr, &stderr)
		candidates, err := gitcmd.CollectLocalBranchCandidates(r, gitcmd.CandidateOptions{
			CurrentBranch:        "feat/current",
			DefaultBranch:        "main",
			AllowCheckedOutDir:   repoDir,
			IncludeUnbornCurrent: true,
		})
		if err != nil {
			t.Fatalf("CollectLocalBranchCandidates failed: %v", err)
		}

		var gotOrder []string
		var fzfInput strings.Builder
		for _, c := range candidates {
			gotOrder = append(gotOrder, c.Name)
			fzfInput.WriteString(gitcmd.FormatCandidateLine(c))
			fzfInput.WriteByte('\n')
		}

		wantOrder := []string{"feat/current", "main", "mine-unmerged", "other-unmerged", "merged-mine"}
		if strings.Join(gotOrder, ",") != strings.Join(wantOrder, ",") {
			t.Fatalf("candidate order = %v, want %v", gotOrder, wantOrder)
		}
		if got := gitcmd.CountInitialSelections(candidates); got != 2 {
			t.Errorf("CountInitialSelections = %d, want 2", got)
		}

		// Verify fzfInteractiveArgs works with real fzf --filter and returns only the branch name.
		filterArgs := append([]string{"--filter=mine-unmerged"}, fzfInteractiveArgs("git-migrate-clean-bare", repoDir, "main", "feat/current", 2)...)
		fzfCmd := exec.Command("fzf", filterArgs...)
		fzfCmd.Stdin = strings.NewReader(fzfInput.String())
		fzfOut, err := fzfCmd.Output()
		if err != nil {
			t.Fatalf("fzf --filter failed: %v", err)
		}
		if got := strings.TrimSpace(string(fzfOut)); got != "mine-unmerged" {
			t.Errorf("fzf output = %q, want mine-unmerged", got)
		}

		// Verify _preview renders branch path, diff stat, and commit summary.
		var previewOut, previewErr bytes.Buffer
		if err := run([]string{"_preview", repoDir, "main", "mine-unmerged"}, "", &previewOut, &previewErr); err != nil {
			t.Fatalf("_preview failed: %v, stderr: %s", err, previewErr.String())
		}
		previewText := previewOut.String()
		for _, want := range []string{"Branch:   mine-unmerged", filepath.Join(repoDir, "mine-unmerged"), "Diff vs main:", "My topic work"} {
			if !strings.Contains(previewText, want) {
				t.Errorf("_preview missing %q:\n%s", want, previewText)
			}
		}
	})

	t.Run("always invokes interactive selector even with single branch and supports --dry-run", func(t *testing.T) {
		isolateEnv(t)
		_, repoDir := setupStandardClone(t, "main")

		called := false
		selector := func(_, _, _ string, candidates []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			called = true
			if len(candidates) != 1 || candidates[0].Name != "main" {
				t.Fatalf("unexpected candidates: %+v", candidates)
			}
			return []string{"main"}, nil
		}

		var stdout, stderr bytes.Buffer
		if err := runWithOptions([]string{"--interactive", "--dry-run", repoDir}, "", selector, &stdout, &stderr); err != nil {
			t.Fatalf("interactive dry-run failed: %v, stderr: %s", err, stderr.String())
		}
		if !called {
			t.Fatal("expected selector to be invoked even when only current/default branch exists")
		}
		if !strings.Contains(stdout.String(), "[dry-run] convert "+repoDir) {
			t.Errorf("unexpected dry-run output:\n%s", stdout.String())
		}
		if got := runGit(t, repoDir, "rev-parse", "--is-bare-repository"); got != "false" {
			t.Errorf("dry-run modified bare state: %s", got)
		}
	})

	t.Run("migrates multiple selected branches and inherits direnv trust only for matching .envrc", func(t *testing.T) {
		isolateEnv(t)
		_, repoDir := setupStandardClone(t, "main")

		sharedEnvrc := "export TEST_ENV=shared\n"
		writeFile(t, filepath.Join(repoDir, ".envrc"), sharedEnvrc)
		runGit(t, repoDir, "add", ".envrc")
		runGit(t, repoDir, "commit", "-m", "Add shared .envrc")

		runGit(t, repoDir, "checkout", "-b", "feat/same-envrc")
		writeFile(t, filepath.Join(repoDir, "same.txt"), "same\n")
		runGit(t, repoDir, "add", "same.txt")
		runGit(t, repoDir, "commit", "-m", "Same envrc branch")

		runGit(t, repoDir, "checkout", "-b", "feat/tampered-envrc", "main")
		writeFile(t, filepath.Join(repoDir, ".envrc"), "export TEST_ENV=evil\n")
		runGit(t, repoDir, "add", ".envrc")
		runGit(t, repoDir, "commit", "-m", "Different envrc branch")

		runGit(t, repoDir, "checkout", "main")
		runDirenvAllow(t, repoDir)

		selector := func(_, _, _ string, _ []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			return []string{"main", "feat/same-envrc", "feat/tampered-envrc"}, nil
		}

		var stdout, stderr bytes.Buffer
		if err := runWithOptions([]string{"--interactive", repoDir}, "", selector, &stdout, &stderr); err != nil {
			t.Fatalf("interactive migrate failed: %v, stderr: %s", err, stderr.String())
		}

		mainWT := filepath.Join(repoDir, "main")
		sameWT := filepath.Join(repoDir, "feat-same-envrc")
		tamperedWT := filepath.Join(repoDir, "feat-tampered-envrc")

		if got := strings.TrimSpace(stdout.String()); got != mainWT {
			t.Fatalf("stdout = %q, want %q", got, mainWT)
		}
		if got := runGit(t, sameWT, "symbolic-ref", "--short", "HEAD"); got != "feat/same-envrc" {
			t.Errorf("sameWT branch = %q, want feat/same-envrc", got)
		}
		if got := readFile(t, filepath.Join(sameWT, "same.txt")); got != "same\n" {
			t.Errorf("same.txt = %q, want same\\n", got)
		}
		if got := runGit(t, tamperedWT, "symbolic-ref", "--short", "HEAD"); got != "feat/tampered-envrc" {
			t.Errorf("tamperedWT branch = %q, want feat/tampered-envrc", got)
		}

		if state := direnvAllowedState(t, mainWT); state != 0 {
			t.Errorf("expected mainWT .envrc allowed, got %d", state)
		}
		if state := direnvAllowedState(t, sameWT); state != 0 {
			t.Errorf("expected sameWT matching .envrc allowed, got %d", state)
		}
		if state := direnvAllowedState(t, tamperedWT); state == 0 {
			t.Errorf("expected tamperedWT differing .envrc NOT to be allowed, got %d", state)
		}

		// With --trust, differing .envrc is allowed explicitly.
		_, trustedRepo := setupStandardClone(t, "main")
		writeFile(t, filepath.Join(trustedRepo, ".envrc"), "export A=1\n")
		runGit(t, trustedRepo, "add", ".envrc")
		runGit(t, trustedRepo, "commit", "-m", "envrc")
		runGit(t, trustedRepo, "checkout", "-b", "topic")
		writeFile(t, filepath.Join(trustedRepo, ".envrc"), "export A=2\n")
		runGit(t, trustedRepo, "add", ".envrc")
		runGit(t, trustedRepo, "commit", "-m", "topic envrc")
		runGit(t, trustedRepo, "checkout", "main")

		stdout.Reset()
		stderr.Reset()
		trustSelector := func(_, _, _ string, _ []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			return []string{"main", "topic"}, nil
		}
		if err := runWithOptions([]string{"--interactive", "--trust", trustedRepo}, "", trustSelector, &stdout, &stderr); err != nil {
			t.Fatalf("interactive --trust migrate failed: %v, stderr: %s", err, stderr.String())
		}
		if state := direnvAllowedState(t, filepath.Join(trustedRepo, "topic")); state != 0 {
			t.Errorf("expected topic .envrc allowed with --trust, got %d", state)
		}
	})

	t.Run("fails closed on selector cancel and flattened directory collisions", func(t *testing.T) {
		isolateEnv(t)
		_, repoDir := setupStandardClone(t, "main")
		runGit(t, repoDir, "branch", "feat/a")
		runGit(t, repoDir, "branch", "feat-a")

		// 1. Selector cancel leaves repo untouched.
		cancelSelector := func(_, _, _ string, _ []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			return nil, errors.New("migration canceled")
		}
		var stdout, stderr bytes.Buffer
		if err := runWithOptions([]string{"--interactive", repoDir}, "", cancelSelector, &stdout, &stderr); err == nil {
			t.Fatal("expected error when selector cancels, got nil")
		}
		if got := runGit(t, repoDir, "rev-parse", "--is-bare-repository"); got != "false" {
			t.Errorf("repo became bare after cancel")
		}

		// 2. Directory collision between feat/a and feat-a aborts before mutating repo.
		collideSelector := func(_, _, _ string, _ []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			return []string{"main", "feat/a", "feat-a"}, nil
		}
		stdout.Reset()
		stderr.Reset()
		if err := runWithOptions([]string{"--interactive", repoDir}, "", collideSelector, &stdout, &stderr); err == nil {
			t.Fatal("expected collision error, got nil")
		}
		if got := runGit(t, repoDir, "rev-parse", "--is-bare-repository"); got != "false" {
			t.Errorf("repo became bare after collision error")
		}
	})
}

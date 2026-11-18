package main

import (
	"bytes"
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
	t.Setenv("GIT_CONFIG_GLOBAL", "/dev/null")
	t.Setenv("GIT_CONFIG_SYSTEM", "/dev/null")
	t.Setenv("GIT_TERMINAL_PROMPT", "0")
}

func runGit(t *testing.T, dir string, args ...string) string {
	t.Helper()
	cmd := exec.Command("git", args...)
	cmd.Dir = dir
	cmd.Env = gitcmd.IsolatedEnv(os.Environ())
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("git %s failed: %v: %s", strings.Join(args, " "), err, string(out))
	}
	return strings.TrimSpace(string(out))
}

func initSeedRepo(t *testing.T, dir, defaultBranch string) string {
	t.Helper()
	runGit(t, filepath.Dir(dir), "init", "-b", defaultBranch, dir)
	runGit(t, dir, "config", "user.name", "Tester")
	runGit(t, dir, "config", "user.email", "tester@example.com")
	if err := os.WriteFile(filepath.Join(dir, "README.md"), []byte("initial\n"), 0o644); err != nil {
		t.Fatalf("write README: %v", err)
	}
	runGit(t, dir, "add", ".")
	runGit(t, dir, "commit", "-m", "Initial commit")
	return runGit(t, dir, "rev-parse", "HEAD")
}

func advanceSeedRepo(t *testing.T, dir, fileName string) string {
	t.Helper()
	if err := os.WriteFile(filepath.Join(dir, fileName), []byte(fileName+"\n"), 0o644); err != nil {
		t.Fatalf("write %s: %v", fileName, err)
	}
	runGit(t, dir, "add", ".")
	runGit(t, dir, "commit", "-m", "Add "+fileName)
	return runGit(t, dir, "rev-parse", "HEAD")
}

func TestRun(t *testing.T) {
	t.Run("updates clean-bare default worktree from bare root with GIT_DIR=.git and from another worktree", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		seed := filepath.Join(temp, "seed")
		initSeedRepo(t, seed, "main")

		repoDir := filepath.Join(temp, "repo")
		if err := os.MkdirAll(repoDir, 0o755); err != nil {
			t.Fatalf("mkdir repoDir: %v", err)
		}
		runGit(t, repoDir, "clone", "--bare", seed, filepath.Join(repoDir, ".git"))
		runGit(t, repoDir, "config", "set", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*")
		runGit(t, repoDir, "fetch", "--quiet", "origin")
		runGit(t, repoDir, "remote", "set-head", "origin", "--auto")

		mainWT := filepath.Join(repoDir, "main")
		featWT := filepath.Join(repoDir, "feat")
		runGit(t, repoDir, "worktree", "add", mainWT, "main")
		runGit(t, repoDir, "worktree", "add", "-b", "feat", featWT, "main")

		// Advance origin and run from bare root with GIT_DIR=.git (as `git all` does).
		commit1 := advanceSeedRepo(t, seed, "one.txt")
		t.Setenv("GIT_DIR", ".git")
		var stdout, stderr bytes.Buffer
		if err := run(nil, repoDir, &stdout, &stderr); err != nil {
			t.Fatalf("run from bare root failed: %v, stderr: %s", err, stderr.String())
		}
		if got := runGit(t, mainWT, "rev-parse", "HEAD"); got != commit1 {
			t.Errorf("mainWT HEAD = %s, want %s", got, commit1)
		}

		// Advance origin again and run from linked feature worktree with worktree GIT_DIR.
		commit2 := advanceSeedRepo(t, seed, "two.txt")
		t.Setenv("GIT_DIR", filepath.Join(repoDir, ".git", "worktrees", "feat"))
		stdout.Reset()
		stderr.Reset()
		if err := run(nil, featWT, &stdout, &stderr); err != nil {
			t.Fatalf("run from featWT failed: %v, stderr: %s", err, stderr.String())
		}
		if got := runGit(t, mainWT, "rev-parse", "HEAD"); got != commit2 {
			t.Errorf("mainWT HEAD = %s, want %s", got, commit2)
		}
	})

	t.Run("fetches default branch directly in bare repo without default worktree under worktree GIT_DIR", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		seed := filepath.Join(temp, "seed")
		initSeedRepo(t, seed, "trunk")

		repoDir := filepath.Join(temp, "repo")
		if err := os.MkdirAll(repoDir, 0o755); err != nil {
			t.Fatalf("mkdir repoDir: %v", err)
		}
		runGit(t, repoDir, "clone", "--bare", seed, filepath.Join(repoDir, ".git"))
		runGit(t, repoDir, "config", "set", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*")
		runGit(t, repoDir, "fetch", "--quiet", "origin")
		runGit(t, repoDir, "remote", "set-head", "origin", "--auto")

		featWT := filepath.Join(repoDir, "feat")
		runGit(t, repoDir, "worktree", "add", "-b", "feat", featWT, "trunk")

		commit1 := advanceSeedRepo(t, seed, "bare-update.txt")
		t.Setenv("GIT_DIR", filepath.Join(repoDir, ".git", "worktrees", "feat"))
		var stdout, stderr bytes.Buffer
		if err := run(nil, featWT, &stdout, &stderr); err != nil {
			t.Fatalf("run without default worktree failed: %v, stderr: %s", err, stderr.String())
		}
		if got := runGit(t, repoDir, "rev-parse", "refs/heads/trunk"); got != commit1 {
			t.Errorf("refs/heads/trunk = %s, want %s", got, commit1)
		}
	})

	t.Run("prefers upstream remote over origin and switches legacy non-bare repo to default branch", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		originSeed := filepath.Join(temp, "origin")
		upstreamSeed := filepath.Join(temp, "upstream")
		initSeedRepo(t, originSeed, "main")

		// Clone upstream from origin so both share history, then advance upstream only.
		runGit(t, temp, "clone", originSeed, upstreamSeed)
		runGit(t, upstreamSeed, "config", "user.name", "Tester")
		runGit(t, upstreamSeed, "config", "user.email", "tester@example.com")
		upstreamCommit := advanceSeedRepo(t, upstreamSeed, "upstream.txt")

		legacyDir := filepath.Join(temp, "legacy")
		runGit(t, temp, "clone", originSeed, legacyDir)
		runGit(t, legacyDir, "remote", "add", "upstream", upstreamSeed)
		runGit(t, legacyDir, "checkout", "-b", "topic")

		var stdout, stderr bytes.Buffer
		if err := run(nil, legacyDir, &stdout, &stderr); err != nil {
			t.Fatalf("run in legacy repo failed: %v, stderr: %s", err, stderr.String())
		}
		if br := runGit(t, legacyDir, "symbolic-ref", "--short", "HEAD"); br != "main" {
			t.Errorf("checked out branch = %q, want main", br)
		}
		if got := runGit(t, legacyDir, "rev-parse", "HEAD"); got != upstreamCommit {
			t.Errorf("legacy HEAD = %s, want upstream commit %s", got, upstreamCommit)
		}
	})
}

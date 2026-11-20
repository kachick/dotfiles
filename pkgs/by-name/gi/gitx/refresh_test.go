package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func initSeedRepo(t *testing.T, dir, defaultBranch string) string {
	t.Helper()
	runGit(t, filepath.Dir(dir), "init", "-b", defaultBranch, dir)
	runGit(t, dir, "config", "user.name", "Tester")
	runGit(t, dir, "config", "user.email", "tester@example.com")
	writeTestFile(t, filepath.Join(dir, "README.md"), "initial\n")
	runGit(t, dir, "add", ".")
	runGit(t, dir, "commit", "-m", "Initial commit")
	return runGit(t, dir, "rev-parse", "HEAD")
}

func advanceSeedRepo(t *testing.T, dir, fileName string) string {
	t.Helper()
	writeTestFile(t, filepath.Join(dir, fileName), fileName+"\n")
	runGit(t, dir, "add", ".")
	runGit(t, dir, "commit", "-m", "Add "+fileName)
	return runGit(t, dir, "rev-parse", "HEAD")
}

func TestRunRefresh(t *testing.T) {
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
		if err := runRefresh(nil, repoDir, &stdout, &stderr); err != nil {
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
		if err := runRefresh(nil, featWT, &stdout, &stderr); err != nil {
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
		if err := runRefresh(nil, featWT, &stdout, &stderr); err != nil {
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
		if err := runRefresh(nil, legacyDir, &stdout, &stderr); err != nil {
			t.Fatalf("run in legacy repo failed: %v, stderr: %s", err, stderr.String())
		}
		if br := runGit(t, legacyDir, "symbolic-ref", "--short", "HEAD"); br != "main" {
			t.Errorf("checked out branch = %q, want main", br)
		}
		if got := runGit(t, legacyDir, "rev-parse", "HEAD"); got != upstreamCommit {
			t.Errorf("legacy HEAD = %s, want upstream commit %s", got, upstreamCommit)
		}
	})

	t.Run("warns when clean-bare default worktree directory is checked out on another branch", func(t *testing.T) {
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
		runGit(t, repoDir, "worktree", "add", "-b", "topic", mainWT, "main")

		commit1 := advanceSeedRepo(t, seed, "warning-test.txt")
		var stdout, stderr bytes.Buffer
		if err := runRefresh(nil, repoDir, &stdout, &stderr); err != nil {
			t.Fatalf("runRefresh failed: %v, stderr: %s", err, stderr.String())
		}
		if got := runGit(t, repoDir, "rev-parse", "refs/heads/main"); got != commit1 {
			t.Errorf("refs/heads/main = %s, want %s", got, commit1)
		}
		if !strings.Contains(stderr.String(), "default worktree") {
			t.Errorf("expected warning about default worktree in stderr, got: %s", stderr.String())
		}
	})
}

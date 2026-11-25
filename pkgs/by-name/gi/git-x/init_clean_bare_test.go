package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func setupInitSeedRepo(t *testing.T, defaultBranch string, withEnvrc bool) string {
	t.Helper()
	temp := t.TempDir()
	seedDir := filepath.Join(temp, "seed")
	runGit(t, temp, "init", "-b", defaultBranch, seedDir)
	runGit(t, seedDir, "config", "user.name", "Tester")
	runGit(t, seedDir, "config", "user.email", "tester@example.com")

	writeTestFile(t, filepath.Join(seedDir, "README.md"), "hello\n")
	if withEnvrc {
		writeTestFile(t, filepath.Join(seedDir, ".envrc"), "export TEST_VAR=1\n")
	}
	runGit(t, seedDir, "add", ".")
	runGit(t, seedDir, "commit", "-m", "Initial commit")
	return seedDir
}

func cloneCleanBare(t *testing.T, seedDir, repoDir string) {
	t.Helper()
	if err := os.MkdirAll(repoDir, 0o755); err != nil {
		t.Fatalf("mkdir repoDir: %v", err)
	}
	runGit(t, repoDir, "clone", "--bare", seedDir, filepath.Join(repoDir, ".git"))
}

func TestRun_CleanBareInitialization(t *testing.T) {
	t.Run("initializes non-main default branch, configures fetch refspec, and sets upstream", func(t *testing.T) {
		isolateEnv(t)
		seedDir := setupInitSeedRepo(t, "trunk", false)
		repoDir := filepath.Join(t.TempDir(), "my-repo")
		cloneCleanBare(t, seedDir, repoDir)

		var stdout, stderr bytes.Buffer
		if err := runInitCleanBare([]string{repoDir}, &stdout, &stderr); err != nil {
			t.Fatalf("run failed: %v, stderr: %s", err, stderr.String())
		}

		gotPath := strings.TrimSpace(stdout.String())
		wantPath := filepath.Join(repoDir, "trunk")
		if gotPath != wantPath {
			t.Fatalf("stdout = %q, want %q", gotPath, wantPath)
		}

		fetchSpec := runGit(t, repoDir, "config", "--get", "remote.origin.fetch")
		if fetchSpec != "+refs/heads/*:refs/remotes/origin/*" {
			t.Errorf("remote.origin.fetch = %q", fetchSpec)
		}

		upstream := runGit(t, wantPath, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
		if upstream != "origin/trunk" {
			t.Errorf("upstream = %q, want origin/trunk", upstream)
		}

		// Re-running must be idempotent and return the same worktree path.
		stdout.Reset()
		stderr.Reset()
		if err := runInitCleanBare([]string{repoDir}, &stdout, &stderr); err != nil {
			t.Fatalf("second run failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != wantPath {
			t.Errorf("second run stdout = %q, want %q", got, wantPath)
		}
	})

	t.Run("does not allow direnv by default, only with --trust", func(t *testing.T) {
		isolateEnv(t)

		seedDir := setupInitSeedRepo(t, "main", true)
		repoDir := filepath.Join(t.TempDir(), "trusted-repo")
		cloneCleanBare(t, seedDir, repoDir)

		var stdout, stderr bytes.Buffer
		if err := runInitCleanBare([]string{repoDir}, &stdout, &stderr); err != nil {
			t.Fatalf("run without --trust failed: %v, stderr: %s", err, stderr.String())
		}
		wtDir := strings.TrimSpace(stdout.String())

		// 0 = allowed, 1 = not allowed, 2 = denied
		if state := direnvAllowedState(t, wtDir); state == 0 {
			t.Fatalf("expected .envrc NOT to be allowed without --trust, got state=%d", state)
		}

		stdout.Reset()
		stderr.Reset()
		if err := runInitCleanBare([]string{"--trust", repoDir}, &stdout, &stderr); err != nil {
			t.Fatalf("run with --trust failed: %v, stderr: %s", err, stderr.String())
		}
		if state := direnvAllowedState(t, wtDir); state != 0 {
			t.Fatalf("expected .envrc to be allowed with --trust, got state=%d", state)
		}
	})

	t.Run("handles empty repository with unborn HEAD", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		seedDir := filepath.Join(temp, "empty-seed")
		runGit(t, temp, "init", "-b", "trunk", seedDir)

		repoDir := filepath.Join(t.TempDir(), "empty-repo")
		cloneCleanBare(t, seedDir, repoDir)

		var stdout, stderr bytes.Buffer
		if err := runInitCleanBare([]string{repoDir}, &stdout, &stderr); err != nil {
			t.Fatalf("run on empty repo failed: %v, stderr: %s", err, stderr.String())
		}
		wtDir := strings.TrimSpace(stdout.String())
		wantDir := filepath.Join(repoDir, "trunk")
		if wtDir != wantDir {
			t.Fatalf("stdout = %q, want %q", wtDir, wantDir)
		}
		branch := runGit(t, wtDir, "symbolic-ref", "--short", "HEAD")
		if branch != "trunk" {
			t.Errorf("branch = %q, want trunk", branch)
		}
	})

	t.Run("returns repoDir unchanged for legacy non-bare repository", func(t *testing.T) {
		isolateEnv(t)
		seedDir := setupInitSeedRepo(t, "main", false)
		var stdout, stderr bytes.Buffer
		if err := runInitCleanBare([]string{seedDir}, &stdout, &stderr); err != nil {
			t.Fatalf("run on non-bare repo failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != seedDir {
			t.Errorf("stdout = %q, want %q", got, seedDir)
		}
	})
}

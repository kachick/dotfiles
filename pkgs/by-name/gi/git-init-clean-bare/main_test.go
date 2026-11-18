package main

import (
	"bytes"
	"encoding/json"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func runGit(t *testing.T, dir string, args ...string) string {
	t.Helper()
	cmd := exec.Command("git", args...)
	cmd.Dir = dir
	// Disable commit signing and global hooks/config interference in unit tests.
	cmd.Env = append(os.Environ(), "GIT_CONFIG_GLOBAL=/dev/null", "GIT_CONFIG_SYSTEM=/dev/null")
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("git %s failed: %v: %s", strings.Join(args, " "), err, string(out))
	}
	return strings.TrimSpace(string(out))
}

func setupSeedRepo(t *testing.T, defaultBranch string, withEnvrc bool) string {
	t.Helper()
	temp := t.TempDir()
	seedDir := filepath.Join(temp, "seed")
	runGit(t, temp, "init", "-b", defaultBranch, seedDir)
	runGit(t, seedDir, "config", "user.name", "Tester")
	runGit(t, seedDir, "config", "user.email", "tester@example.com")

	if err := os.WriteFile(filepath.Join(seedDir, "README.md"), []byte("hello\n"), 0o644); err != nil {
		t.Fatalf("write README: %v", err)
	}
	if withEnvrc {
		if err := os.WriteFile(filepath.Join(seedDir, ".envrc"), []byte("export TEST_VAR=1\n"), 0o644); err != nil {
			t.Fatalf("write .envrc: %v", err)
		}
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

func TestRun_CleanBareInitialization(t *testing.T) {
	t.Run("initializes non-main default branch, configures fetch refspec, and sets upstream", func(t *testing.T) {
		seedDir := setupSeedRepo(t, "trunk", false)
		repoDir := filepath.Join(t.TempDir(), "my-repo")
		cloneCleanBare(t, seedDir, repoDir)

		var stdout, stderr bytes.Buffer
		if err := run([]string{repoDir}, &stdout, &stderr); err != nil {
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
		if err := run([]string{repoDir}, &stdout, &stderr); err != nil {
			t.Fatalf("second run failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != wantPath {
			t.Errorf("second run stdout = %q, want %q", got, wantPath)
		}
	})

	t.Run("does not allow direnv by default, only with --trust", func(t *testing.T) {
		t.Setenv("XDG_DATA_HOME", filepath.Join(t.TempDir(), "xdg-data"))
		t.Setenv("XDG_CONFIG_HOME", filepath.Join(t.TempDir(), "xdg-config"))

		seedDir := setupSeedRepo(t, "main", true)
		repoDir := filepath.Join(t.TempDir(), "trusted-repo")
		cloneCleanBare(t, seedDir, repoDir)

		var stdout, stderr bytes.Buffer
		if err := run([]string{repoDir}, &stdout, &stderr); err != nil {
			t.Fatalf("run without --trust failed: %v, stderr: %s", err, stderr.String())
		}
		wtDir := strings.TrimSpace(stdout.String())

		// 0 = allowed, 1 = not allowed, 2 = denied
		if state := direnvAllowedState(t, wtDir); state == 0 {
			t.Fatalf("expected .envrc NOT to be allowed without --trust, got state=%d", state)
		}

		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"--trust", repoDir}, &stdout, &stderr); err != nil {
			t.Fatalf("run with --trust failed: %v, stderr: %s", err, stderr.String())
		}
		if state := direnvAllowedState(t, wtDir); state != 0 {
			t.Fatalf("expected .envrc to be allowed with --trust, got state=%d", state)
		}
	})

	t.Run("handles empty repository with unborn HEAD", func(t *testing.T) {
		temp := t.TempDir()
		seedDir := filepath.Join(temp, "empty-seed")
		runGit(t, temp, "init", "-b", "trunk", seedDir)

		repoDir := filepath.Join(t.TempDir(), "empty-repo")
		cloneCleanBare(t, seedDir, repoDir)

		var stdout, stderr bytes.Buffer
		if err := run([]string{repoDir}, &stdout, &stderr); err != nil {
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
		seedDir := setupSeedRepo(t, "main", false)
		var stdout, stderr bytes.Buffer
		if err := run([]string{seedDir}, &stdout, &stderr); err != nil {
			t.Fatalf("run on non-bare repo failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != seedDir {
			t.Errorf("stdout = %q, want %q", got, seedDir)
		}
	})
}

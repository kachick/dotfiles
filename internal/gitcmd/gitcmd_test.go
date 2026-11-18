package gitcmd

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func isolateTestEnv(t *testing.T) {
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
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("git %s failed: %v: %s", strings.Join(args, " "), err, string(out))
	}
	return strings.TrimSpace(string(out))
}

func setupBareRepo(t *testing.T) (repoDir, wtDir string) {
	t.Helper()
	temp := t.TempDir()
	seed := filepath.Join(temp, "seed")
	runGit(t, temp, "init", "-b", "trunk", seed)
	runGit(t, seed, "config", "user.name", "Tester")
	runGit(t, seed, "config", "user.email", "tester@example.com")
	if err := os.WriteFile(filepath.Join(seed, "README.md"), []byte("hello\n"), 0o644); err != nil {
		t.Fatalf("write README: %v", err)
	}
	runGit(t, seed, "add", ".")
	runGit(t, seed, "commit", "-m", "Initial commit")

	repoDir = filepath.Join(temp, "repo")
	if err := os.MkdirAll(repoDir, 0o755); err != nil {
		t.Fatalf("mkdir repoDir: %v", err)
	}
	runGit(t, repoDir, "clone", "--bare", seed, filepath.Join(repoDir, ".git"))
	wtDir = filepath.Join(repoDir, "trunk")
	runGit(t, repoDir, "worktree", "add", wtDir, "trunk")
	return repoDir, wtDir
}

func TestIsolatedEnv(t *testing.T) {
	base := []string{
		"PATH=/usr/bin",
		"GIT_DIR=.git",
		"GIT_WORK_TREE=/tmp/wt",
		"GIT_INDEX_FILE=/tmp/idx",
		"GIT_CONFIG_GLOBAL=/dev/null",
		"GIT_CONFIG_PARAMETERS='color.ui'='false'",
	}
	got := IsolatedEnv(base)
	joined := strings.Join(got, "\n")
	for _, dropped := range []string{"GIT_DIR=", "GIT_WORK_TREE=", "GIT_INDEX_FILE="} {
		if strings.Contains(joined, dropped) {
			t.Errorf("expected %s to be stripped, got:\n%s", dropped, joined)
		}
	}
	for _, kept := range []string{"PATH=/usr/bin", "GIT_CONFIG_GLOBAL=/dev/null", "GIT_CONFIG_PARAMETERS="} {
		if !strings.Contains(joined, kept) {
			t.Errorf("expected %s to be preserved, got:\n%s", kept, joined)
		}
	}
}

func TestDetectRepoContext_SurvivesInheritedGitDir(t *testing.T) {
	t.Run("handles GIT_DIR=.git at clean-bare root", func(t *testing.T) {
		isolateTestEnv(t)
		repoDir, _ := setupBareRepo(t)
		t.Setenv("GIT_DIR", ".git")

		var stdout, stderr bytes.Buffer
		ctx, err := DetectRepoContext(repoDir, &stdout, &stderr)
		if err != nil {
			t.Fatalf("DetectRepoContext failed: %v", err)
		}
		if !ctx.IsBare {
			t.Errorf("expected IsBare=true, got false")
		}
		if ctx.CommonDir != filepath.Join(repoDir, ".git") {
			t.Errorf("CommonDir = %q, want %q", ctx.CommonDir, filepath.Join(repoDir, ".git"))
		}
		if ctx.ContainerDir != repoDir {
			t.Errorf("ContainerDir = %q, want %q", ctx.ContainerDir, repoDir)
		}

		defaultBranch, err := DetectDefaultBranch(NewIsolated(ctx.CommonDir, &stdout, &stderr), ctx.CommonDir, ctx.IsBare)
		if err != nil {
			t.Fatalf("DetectDefaultBranch failed: %v", err)
		}
		if defaultBranch != "trunk" {
			t.Errorf("defaultBranch = %q, want trunk", defaultBranch)
		}
	})

	t.Run("handles linked worktree GIT_DIR inside alias", func(t *testing.T) {
		isolateTestEnv(t)
		repoDir, wtDir := setupBareRepo(t)
		t.Setenv("GIT_DIR", filepath.Join(repoDir, ".git", "worktrees", "trunk"))

		var stdout, stderr bytes.Buffer
		ctx, err := DetectRepoContext(wtDir, &stdout, &stderr)
		if err != nil {
			t.Fatalf("DetectRepoContext failed: %v", err)
		}
		if !ctx.IsBare {
			t.Errorf("expected IsBare=true even when GIT_DIR points to linked worktree, got false")
		}
	})
}

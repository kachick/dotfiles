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
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("git %s failed: %v: %s", strings.Join(args, " "), err, string(out))
	}
	return strings.TrimSpace(string(out))
}

func setupCleanBareRepo(t *testing.T, defaultBranch string, remoteBranches []string, envrcContent string) (repoDir, defaultWT string) {
	t.Helper()
	temp := t.TempDir()
	seedDir := filepath.Join(temp, "seed")
	runGit(t, temp, "init", "-b", defaultBranch, seedDir)
	runGit(t, seedDir, "config", "user.name", "Tester")
	runGit(t, seedDir, "config", "user.email", "tester@example.com")

	if err := os.WriteFile(filepath.Join(seedDir, "README.md"), []byte("hello\n"), 0o644); err != nil {
		t.Fatalf("write README: %v", err)
	}
	if envrcContent != "" {
		if err := os.WriteFile(filepath.Join(seedDir, ".envrc"), []byte(envrcContent), 0o644); err != nil {
			t.Fatalf("write .envrc: %v", err)
		}
	}
	runGit(t, seedDir, "add", ".")
	runGit(t, seedDir, "commit", "-m", "Initial commit")

	for _, br := range remoteBranches {
		runGit(t, seedDir, "checkout", "-b", br)
		marker := filepath.Join(seedDir, strings.ReplaceAll(br, "/", "-")+".txt")
		if err := os.WriteFile(marker, []byte(br+"\n"), 0o644); err != nil {
			t.Fatalf("write branch marker: %v", err)
		}
		runGit(t, seedDir, "add", ".")
		runGit(t, seedDir, "commit", "-m", "Commit on "+br)
		runGit(t, seedDir, "checkout", defaultBranch)
	}

	repoDir = filepath.Join(temp, "my-repo")
	if err := os.MkdirAll(repoDir, 0o755); err != nil {
		t.Fatalf("mkdir repoDir: %v", err)
	}
	runGit(t, repoDir, "clone", "--bare", seedDir, filepath.Join(repoDir, ".git"))
	runGit(t, repoDir, "config", "set", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*")
	runGit(t, repoDir, "fetch", "--quiet", "origin")
	runGit(t, repoDir, "remote", "set-head", "origin", "--auto")

	defaultWT = filepath.Join(repoDir, defaultBranch)
	runGit(t, repoDir, "worktree", "add", defaultWT, defaultBranch)

	// Delete remote branches locally after bare clone only if needed per test; here keep default branch local
	// and remove non-default local heads so tests can verify remote-tracking checkout.
	for _, br := range remoteBranches {
		runGit(t, repoDir, "branch", "-D", br)
	}
	return repoDir, defaultWT
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

func TestRun_AddListPath(t *testing.T) {
	t.Run("creates worktrees for new, local, and remote branches with flat slash sanitization", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/remote-one"}, "")

		// Create a local-only branch to verify checking out an existing local branch.
		runGit(t, defaultWT, "branch", "local-only")

		// 1. New branch with slash in name
		var stdout, stderr bytes.Buffer
		if err := run([]string{"add", "feat/new-one"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add new branch failed: %v, stderr: %s", err, stderr.String())
		}
		gotNew := strings.TrimSpace(stdout.String())
		wantNew := filepath.Join(repoDir, "feat-new-one")
		if gotNew != wantNew {
			t.Fatalf("new worktree path = %q, want %q", gotNew, wantNew)
		}
		if br := runGit(t, gotNew, "symbolic-ref", "--short", "HEAD"); br != "feat/new-one" {
			t.Errorf("checked out branch = %q, want feat/new-one", br)
		}
		// New branch must NOT track origin/main (--no-track).
		if cmd := exec.Command("git", "-C", gotNew, "rev-parse", "--abbrev-ref", "@{u}"); cmd.Run() == nil {
			t.Errorf("expected new branch not to have an upstream tracking branch")
		}

		// Re-running add for the same branch returns existing path idempotently.
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"add", "feat/new-one"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("idempotent add failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != wantNew {
			t.Errorf("idempotent stdout = %q, want %q", got, wantNew)
		}

		// 2. Existing local branch
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"add", "local-only"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add local branch failed: %v, stderr: %s", err, stderr.String())
		}
		wantLocal := filepath.Join(repoDir, "local-only")
		if got := strings.TrimSpace(stdout.String()); got != wantLocal {
			t.Errorf("local worktree path = %q, want %q", got, wantLocal)
		}

		// 3. Existing remote branch with slash
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"add", "feat/remote-one"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add remote branch failed: %v, stderr: %s", err, stderr.String())
		}
		wantRemote := filepath.Join(repoDir, "feat-remote-one")
		if got := strings.TrimSpace(stdout.String()); got != wantRemote {
			t.Errorf("remote worktree path = %q, want %q", got, wantRemote)
		}
		upstream := runGit(t, wantRemote, "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}")
		if upstream != "origin/feat/remote-one" {
			t.Errorf("upstream = %q, want origin/feat/remote-one", upstream)
		}

		// 4. list (and default no-args) + fzf filter compatibility
		stdout.Reset()
		stderr.Reset()
		if err := run(nil, wantRemote, &stdout, &stderr); err != nil {
			t.Fatalf("list (no args) failed: %v, stderr: %s", err, stderr.String())
		}
		lines := strings.Split(strings.TrimSpace(stdout.String()), "\n")
		if len(lines) != 4 {
			t.Fatalf("expected 4 worktrees in list, got %d:\n%s", len(lines), stdout.String())
		}
		if !strings.HasPrefix(lines[0], "main\tmain\t"+defaultWT) {
			t.Errorf("expected default branch worktree first, got %q", lines[0])
		}

		fzfCmd := exec.Command("fzf", "--filter=feat-remote", "--delimiter=\t", "--with-nth=1,2", "--accept-nth=3")
		fzfCmd.Stdin = strings.NewReader(stdout.String())
		fzfOut, err := fzfCmd.Output()
		if err != nil {
			t.Fatalf("fzf --filter failed: %v", err)
		}
		if got := strings.TrimSpace(string(fzfOut)); got != wantRemote {
			t.Errorf("fzf output = %q, want %q", got, wantRemote)
		}

		// 5. path subcommand (default omitted, branch name, and sanitized dir name)
		stdout.Reset()
		if err := run([]string{"path"}, wantRemote, &stdout, &stderr); err != nil {
			t.Fatalf("path (default) failed: %v", err)
		}
		if got := strings.TrimSpace(stdout.String()); got != defaultWT {
			t.Errorf("path (default) = %q, want %q", got, defaultWT)
		}

		stdout.Reset()
		if err := run([]string{"path", "feat/new-one"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("path by branch failed: %v", err)
		}
		if got := strings.TrimSpace(stdout.String()); got != wantNew {
			t.Errorf("path by branch = %q, want %q", got, wantNew)
		}

		stdout.Reset()
		if err := run([]string{"path", "feat-remote-one"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("path by dir name failed: %v", err)
		}
		if got := strings.TrimSpace(stdout.String()); got != wantRemote {
			t.Errorf("path by dir name = %q, want %q", got, wantRemote)
		}
	})

	t.Run("detects non-main default branch dynamically and honors --base", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "trunk", nil, "")

		// Advance origin/trunk ahead of local trunk to verify new branches prefer origin/<default>.
		var stdout, stderr bytes.Buffer
		if err := run([]string{"add", "topic-from-trunk"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add on trunk repo failed: %v, stderr: %s", err, stderr.String())
		}
		topicWT := strings.TrimSpace(stdout.String())
		trunkHash := runGit(t, defaultWT, "rev-parse", "HEAD")
		topicHash := runGit(t, topicWT, "rev-parse", "HEAD")
		if topicHash != trunkHash {
			t.Errorf("topic HEAD = %s, want trunk %s", topicHash, trunkHash)
		}

		// Create another commit on topic-from-trunk and point origin/trunk to it.
		if err := os.WriteFile(filepath.Join(topicWT, "base.txt"), []byte("base\n"), 0o644); err != nil {
			t.Fatalf("write base.txt: %v", err)
		}
		runGit(t, topicWT, "config", "user.name", "Tester")
		runGit(t, topicWT, "config", "user.email", "tester@example.com")
		runGit(t, topicWT, "add", "base.txt")
		runGit(t, topicWT, "commit", "-m", "Base commit")
		baseHash := runGit(t, topicWT, "rev-parse", "HEAD")
		runGit(t, repoDir, "update-ref", "refs/remotes/origin/trunk", baseHash)

		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"add", "from-origin-trunk"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add from origin/trunk failed: %v, stderr: %s", err, stderr.String())
		}
		originTopicWT := strings.TrimSpace(stdout.String())
		if got := runGit(t, originTopicWT, "rev-parse", "HEAD"); got != baseHash {
			t.Errorf("from-origin-trunk HEAD = %s, want origin/trunk %s", got, baseHash)
		}

		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"default-branch"}, originTopicWT, &stdout, &stderr); err != nil {
			t.Fatalf("default-branch failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != "trunk" {
			t.Errorf("default-branch = %q, want trunk", got)
		}

		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"add", "--base", "topic-from-trunk", "child-topic"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add with --base failed: %v, stderr: %s", err, stderr.String())
		}
		childWT := strings.TrimSpace(stdout.String())
		if got := runGit(t, childWT, "rev-parse", "HEAD"); got != baseHash {
			t.Errorf("child HEAD = %s, want %s", got, baseHash)
		}
	})

	t.Run("handles direnv trust fail-closed and propagates only identical trusted .envrc", func(t *testing.T) {
		isolateEnv(t)
		_, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/tampered"}, "export SAFE_VAR=1\n")

		// Add a different .envrc in origin/feat/tampered by creating a commit in a temporary worktree.
		tamperWT := filepath.Join(t.TempDir(), "tamper")
		runGit(t, defaultWT, "worktree", "add", "--track", "-b", "feat/tampered", tamperWT, "origin/feat/tampered")
		runGit(t, tamperWT, "config", "user.name", "Attacker")
		runGit(t, tamperWT, "config", "user.email", "attacker@example.com")
		if err := os.WriteFile(filepath.Join(tamperWT, ".envrc"), []byte("export EVIL_VAR=1\n"), 0o644); err != nil {
			t.Fatalf("write tampered .envrc: %v", err)
		}
		runGit(t, tamperWT, "add", ".envrc")
		runGit(t, tamperWT, "commit", "-m", "Modify .envrc")
		runGit(t, tamperWT, "update-ref", "refs/remotes/origin/feat/tampered", "HEAD")
		runGit(t, defaultWT, "worktree", "remove", tamperWT)
		runGit(t, defaultWT, "branch", "-D", "feat/tampered")

		// Without any trusted worktree, new worktree must NOT be allowed.
		var stdout, stderr bytes.Buffer
		if err := run([]string{"add", "untrusted-repo-wt"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add untrusted failed: %v, stderr: %s", err, stderr.String())
		}
		untrustedWT := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, untrustedWT); state == 0 {
			t.Fatalf("expected .envrc NOT to be allowed in untrusted repo, got state=%d", state)
		}

		// Trust the default worktree via direnv allow.
		allowCmd := exec.Command("direnv", "allow", defaultWT)
		if out, err := allowCmd.CombinedOutput(); err != nil {
			t.Fatalf("direnv allow defaultWT failed: %v: %s", err, string(out))
		}

		// New worktree with identical .envrc must be auto-allowed.
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"add", "trusted-wt"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add trusted failed: %v, stderr: %s", err, stderr.String())
		}
		trustedWT := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, trustedWT); state != 0 {
			t.Fatalf("expected identical .envrc to be auto-allowed, got state=%d", state)
		}

		// Branch with modified .envrc must NOT be auto-allowed without --trust.
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"add", "feat/tampered"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add tampered failed: %v, stderr: %s", err, stderr.String())
		}
		tamperedWT := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, tamperedWT); state == 0 {
			t.Fatalf("expected modified .envrc NOT to be auto-allowed, got state=%d", state)
		}

		// Explicit --trust allows even a modified .envrc.
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"add", "--trust", "feat/tampered"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add --trust failed: %v, stderr: %s", err, stderr.String())
		}
		if state := direnvAllowedState(t, tamperedWT); state != 0 {
			t.Fatalf("expected .envrc to be allowed with --trust, got state=%d", state)
		}
	})

	t.Run("fails closed on non-bare repository for add", func(t *testing.T) {
		isolateEnv(t)
		legacyDir := filepath.Join(t.TempDir(), "legacy")
		runGit(t, filepath.Dir(legacyDir), "init", "-b", "main", legacyDir)
		runGit(t, legacyDir, "config", "user.name", "Tester")
		runGit(t, legacyDir, "config", "user.email", "tester@example.com")
		if err := os.WriteFile(filepath.Join(legacyDir, "README.md"), []byte("hi\n"), 0o644); err != nil {
			t.Fatalf("write README: %v", err)
		}
		runGit(t, legacyDir, "add", ".")
		runGit(t, legacyDir, "commit", "-m", "init")

		var stdout, stderr bytes.Buffer
		err := run([]string{"add", "feat-x"}, legacyDir, &stdout, &stderr)
		if err == nil {
			t.Fatal("expected add on non-bare repo to fail, got nil")
		}

		// Verify default-branch prefers main over currently checked-out feature branch in non-bare repos.
		runGit(t, legacyDir, "checkout", "-b", "feat-current")
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"default-branch"}, legacyDir, &stdout, &stderr); err != nil {
			t.Fatalf("default-branch failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != "main" {
			t.Errorf("default-branch = %q, want main", got)
		}
	})

	t.Run("renders git status and recent git log in preview with compatible fzf select args", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/preview"}, "")

		var listOut, stderr bytes.Buffer
		if err := run([]string{"add", "feat/preview"}, defaultWT, &listOut, &stderr); err != nil {
			t.Fatalf("add feat/preview failed: %v, stderr: %s", err, stderr.String())
		}
		previewWT := strings.TrimSpace(listOut.String())

		// Verify preview output contains branch status and recent commit log.
		var previewOut bytes.Buffer
		if err := run([]string{"_preview", previewWT}, repoDir, &previewOut, &stderr); err != nil {
			t.Fatalf("_preview failed: %v, stderr: %s", err, stderr.String())
		}
		previewText := previewOut.String()
		for _, want := range []string{"feat/preview", "Commit on feat/preview"} {
			if !strings.Contains(previewText, want) {
				t.Errorf("expected preview output to contain %q, got:\n%s", want, previewText)
			}
		}

		// Verify fzfSelectArgs works with real fzf --filter to select the matching worktree path.
		listOut.Reset()
		if err := run([]string{"list"}, defaultWT, &listOut, &stderr); err != nil {
			t.Fatalf("list failed: %v", err)
		}
		filterArgs := append([]string{"--filter=feat-preview"}, fzfSelectArgs("git-wt", "")...)
		fzfCmd := exec.Command("fzf", filterArgs...)
		fzfCmd.Stdin = strings.NewReader(listOut.String())
		fzfOut, err := fzfCmd.Output()
		if err != nil {
			t.Fatalf("fzf --filter with fzfSelectArgs failed: %v", err)
		}
		if got := strings.TrimSpace(string(fzfOut)); got != previewWT {
			t.Errorf("fzf output = %q, want %q", got, previewWT)
		}
	})

	t.Run("works from clean-bare root and worktrees when invoked with inherited GIT_DIR from git alias", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "trunk", []string{"feat/one"}, "")

		// Simulate `git <alias>` at clean-bare container root where Git sets GIT_DIR=.git.
		t.Setenv("GIT_DIR", ".git")
		var stdout, stderr bytes.Buffer
		if err := run([]string{"default-branch"}, repoDir, &stdout, &stderr); err != nil {
			t.Fatalf("default-branch from bare root with GIT_DIR=.git failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != "trunk" {
			t.Errorf("default-branch = %q, want trunk", got)
		}

		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"list"}, repoDir, &stdout, &stderr); err != nil {
			t.Fatalf("list from bare root with GIT_DIR=.git failed: %v, stderr: %s", err, stderr.String())
		}
		if !strings.Contains(stdout.String(), defaultWT) {
			t.Errorf("expected list output to include %q, got:\n%s", defaultWT, stdout.String())
		}

		// Simulate `git <alias>` inside a linked worktree where Git sets GIT_DIR=<common>/worktrees/<name>.
		t.Setenv("GIT_DIR", filepath.Join(repoDir, ".git", "worktrees", "trunk"))
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"default-branch"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("default-branch from worktree with worktree GIT_DIR failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != "trunk" {
			t.Errorf("default-branch = %q, want trunk", got)
		}
	})
}

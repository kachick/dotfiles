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
		if err := run([]string{"add", "--branch", "feat/new-one"}, defaultWT, &stdout, &stderr); err != nil {
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
		if err := run([]string{"add", "--branch", "feat/new-one"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("idempotent add failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != wantNew {
			t.Errorf("idempotent stdout = %q, want %q", got, wantNew)
		}

		// 2. Existing local branch
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"add", "--branch", "local-only"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add local branch failed: %v, stderr: %s", err, stderr.String())
		}
		wantLocal := filepath.Join(repoDir, "local-only")
		if got := strings.TrimSpace(stdout.String()); got != wantLocal {
			t.Errorf("local worktree path = %q, want %q", got, wantLocal)
		}

		// 3. Existing remote branch with slash
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"add", "--branch", "feat/remote-one"}, defaultWT, &stdout, &stderr); err != nil {
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
		if err := run([]string{"add", "--branch", "topic-from-trunk"}, defaultWT, &stdout, &stderr); err != nil {
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
		if err := run([]string{"add", "--branch", "from-origin-trunk"}, defaultWT, &stdout, &stderr); err != nil {
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
		if err := run([]string{"add", "--base", "topic-from-trunk", "--branch", "child-topic"}, defaultWT, &stdout, &stderr); err != nil {
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
		if err := run([]string{"add", "--branch", "untrusted-repo-wt"}, defaultWT, &stdout, &stderr); err != nil {
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
		if err := run([]string{"add", "--branch", "trusted-wt"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add trusted failed: %v, stderr: %s", err, stderr.String())
		}
		trustedWT := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, trustedWT); state != 0 {
			t.Fatalf("expected identical .envrc to be auto-allowed, got state=%d", state)
		}

		// Branch with modified .envrc must NOT be auto-allowed without --trust.
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"add", "--branch", "feat/tampered"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add tampered failed: %v, stderr: %s", err, stderr.String())
		}
		tamperedWT := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, tamperedWT); state == 0 {
			t.Fatalf("expected modified .envrc NOT to be auto-allowed, got state=%d", state)
		}

		// Explicit --trust allows even a modified .envrc.
		stdout.Reset()
		stderr.Reset()
		if err := run([]string{"add", "--trust", "--branch", "feat/tampered"}, defaultWT, &stdout, &stderr); err != nil {
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
		err := run([]string{"add", "--branch", "feat-x"}, legacyDir, &stdout, &stderr)
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
		if err := run([]string{"add", "--branch", "feat/preview"}, defaultWT, &listOut, &stderr); err != nil {
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

func TestRun_AddInteractive(t *testing.T) {
	t.Run("rejects positional arguments and conflicting flags", func(t *testing.T) {
		isolateEnv(t)
		_, defaultWT := setupCleanBareRepo(t, "main", nil, "")

		cases := [][]string{
			{"add", "feat-pos"},
			{"add", "--branch", "feat-a", "--interactive"},
			{"add", "--interactive", "--base", "main"},
			{"add", "--base", "main"},
			{"add", "--branch", ""},
		}
		for _, args := range cases {
			var stdout, stderr bytes.Buffer
			if err := run(args, defaultWT, &stdout, &stderr); err == nil {
				t.Errorf("expected error for args %v, got nil", args)
			}
		}
	})

	t.Run("defaults bare add to interactive mode, excludes checked-out branches, propagates direnv trust, and prints single cd target", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "export SHARED=1\n")

		// Create local branches with matching and differing .envrc files without leaving worktrees attached.
		tmpWT := filepath.Join(t.TempDir(), "tmp-same")
		runGit(t, defaultWT, "worktree", "add", "-b", "feat/same-envrc", tmpWT, "main")
		runGit(t, tmpWT, "config", "user.name", "Tester")
		runGit(t, tmpWT, "config", "user.email", "tester@example.com")
		if err := os.WriteFile(filepath.Join(tmpWT, "same.txt"), []byte("same\n"), 0o644); err != nil {
			t.Fatalf("write same.txt: %v", err)
		}
		runGit(t, tmpWT, "add", "same.txt")
		runGit(t, tmpWT, "commit", "-m", "Same envrc")
		runGit(t, defaultWT, "worktree", "remove", tmpWT)

		tamperWT := filepath.Join(t.TempDir(), "tmp-tamper")
		runGit(t, defaultWT, "worktree", "add", "-b", "feat/tampered-envrc", tamperWT, "main")
		runGit(t, tamperWT, "config", "user.name", "Tester")
		runGit(t, tamperWT, "config", "user.email", "tester@example.com")
		if err := os.WriteFile(filepath.Join(tamperWT, ".envrc"), []byte("export EVIL=1\n"), 0o644); err != nil {
			t.Fatalf("write .envrc: %v", err)
		}
		runGit(t, tamperWT, "add", ".envrc")
		runGit(t, tamperWT, "commit", "-m", "Tampered envrc")
		runGit(t, defaultWT, "worktree", "remove", tamperWT)

		runGit(t, defaultWT, "branch", "topic-unpicked")

		// Trust defaultWT so identical .envrc should propagate automatically.
		allowCmd := exec.Command("direnv", "allow", defaultWT)
		if out, err := allowCmd.CombinedOutput(); err != nil {
			t.Fatalf("direnv allow failed: %v: %s", err, string(out))
		}

		var gotCandidateNames []string
		selector := func(_, _ string, candidates []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			for _, c := range candidates {
				gotCandidateNames = append(gotCandidateNames, c.Name)
			}
			return []string{"feat/same-envrc", "feat/tampered-envrc"}, nil
		}

		var stdout, stderr bytes.Buffer
		if err := runWithOptions([]string{"add"}, defaultWT, selector, &stdout, &stderr); err != nil {
			t.Fatalf("add (default interactive) failed: %v, stderr: %s", err, stderr.String())
		}

		// Already checked-out main must be excluded from candidates.
		for _, name := range gotCandidateNames {
			if name == "main" {
				t.Errorf("checked-out branch %q should not appear in candidates: %v", name, gotCandidateNames)
			}
		}
		if len(gotCandidateNames) != 3 {
			t.Errorf("got %d candidates (%v), want 3", len(gotCandidateNames), gotCandidateNames)
		}

		sameWT := filepath.Join(repoDir, "feat-same-envrc")
		tamperedWT := filepath.Join(repoDir, "feat-tampered-envrc")
		if got := strings.TrimSpace(stdout.String()); got != sameWT {
			t.Errorf("stdout = %q, want single path %q", got, sameWT)
		}
		if got := runGit(t, sameWT, "symbolic-ref", "--short", "HEAD"); got != "feat/same-envrc" {
			t.Errorf("sameWT branch = %q, want feat/same-envrc", got)
		}
		if got := runGit(t, tamperedWT, "symbolic-ref", "--short", "HEAD"); got != "feat/tampered-envrc" {
			t.Errorf("tamperedWT branch = %q, want feat/tampered-envrc", got)
		}
		if state := direnvAllowedState(t, sameWT); state != 0 {
			t.Errorf("expected sameWT .envrc auto-allowed, got %d", state)
		}
		if state := direnvAllowedState(t, tamperedWT); state == 0 {
			t.Errorf("expected tamperedWT .envrc NOT to be auto-allowed, got %d", state)
		}
	})

	t.Run("prioritizes current then default then first selected worktree in stdout", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "")

		runGit(t, defaultWT, "branch", "topic-a")
		runGit(t, defaultWT, "branch", "topic-b")

		// Add topic-a worktree and remove defaultWT so main becomes an unattached local branch.
		var stdout, stderr bytes.Buffer
		if err := run([]string{"add", "--branch", "topic-a"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add topic-a failed: %v", err)
		}
		topicAWT := strings.TrimSpace(stdout.String())
		runGit(t, repoDir, "worktree", "remove", defaultWT)

		// Even if topic-b is selected before main, stdout must output main (default branch).
		selector := func(_, _ string, _ []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			return []string{"topic-b", "main"}, nil
		}
		stdout.Reset()
		stderr.Reset()
		if err := runWithOptions([]string{"add", "--interactive"}, topicAWT, selector, &stdout, &stderr); err != nil {
			t.Fatalf("interactive add failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != defaultWT {
			t.Errorf("stdout = %q, want default branch worktree %q", got, defaultWT)
		}

		// Verify direct priority order: current > default > first selected.
		dirs := map[string]string{
			"topic-b": filepath.Join(repoDir, "topic-b"),
			"main":    defaultWT,
			"topic-a": topicAWT,
		}
		if got := selectOutputWorktreePath([]string{"topic-b", "main", "topic-a"}, dirs, "topic-a", "main"); got != topicAWT {
			t.Errorf("current priority = %q, want %q", got, topicAWT)
		}
		if got := selectOutputWorktreePath([]string{"topic-b", "main"}, dirs, "other", "main"); got != defaultWT {
			t.Errorf("default priority = %q, want %q", got, defaultWT)
		}
		if got := selectOutputWorktreePath([]string{"topic-b", "topic-a"}, map[string]string{
			"topic-b": dirs["topic-b"],
			"topic-a": dirs["topic-a"],
		}, "other", "main"); got != dirs["topic-b"] {
			t.Errorf("fallback priority = %q, want %q", got, dirs["topic-b"])
		}
	})

	t.Run("renders branch preview and filters candidates with fzf", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "")

		tmpWT := filepath.Join(t.TempDir(), "tmp-preview")
		runGit(t, defaultWT, "worktree", "add", "-b", "feat/branch-preview", tmpWT, "main")
		runGit(t, tmpWT, "config", "user.name", "Tester")
		runGit(t, tmpWT, "config", "user.email", "tester@example.com")
		if err := os.WriteFile(filepath.Join(tmpWT, "note.txt"), []byte("note\n"), 0o644); err != nil {
			t.Fatalf("write note.txt: %v", err)
		}
		runGit(t, tmpWT, "add", "note.txt")
		runGit(t, tmpWT, "commit", "-m", "Previewable branch commit")
		runGit(t, defaultWT, "worktree", "remove", tmpWT)

		var previewOut, stderr bytes.Buffer
		if err := run([]string{"_preview-branch", repoDir, "main", "feat/branch-preview"}, repoDir, &previewOut, &stderr); err != nil {
			t.Fatalf("_preview-branch failed: %v, stderr: %s", err, stderr.String())
		}
		previewText := previewOut.String()
		for _, want := range []string{
			"Branch:   feat/branch-preview",
			filepath.Join(repoDir, "feat-branch-preview"),
			"Diff vs main:",
			"Previewable branch commit",
		} {
			if !strings.Contains(previewText, want) {
				t.Errorf("_preview-branch missing %q:\n%s", want, previewText)
			}
		}

		r := gitcmd.NewIsolated(repoDir, &stderr, &stderr)
		candidates, err := gitcmd.CollectLocalBranchCandidates(r, gitcmd.CandidateOptions{DefaultBranch: "main"})
		if err != nil {
			t.Fatalf("CollectLocalBranchCandidates failed: %v", err)
		}
		var input strings.Builder
		for _, c := range candidates {
			input.WriteString(gitcmd.FormatCandidateLine(c))
			input.WriteByte('\n')
		}
		filterArgs := append([]string{"--filter=feat/branch-preview"}, fzfAddArgs("git-wt", repoDir, "main")...)
		fzfCmd := exec.Command("fzf", filterArgs...)
		fzfCmd.Stdin = strings.NewReader(input.String())
		fzfOut, err := fzfCmd.Output()
		if err != nil {
			t.Fatalf("fzf --filter failed: %v", err)
		}
		if got := strings.TrimSpace(string(fzfOut)); got != "feat/branch-preview" {
			t.Errorf("fzf output = %q, want feat/branch-preview", got)
		}
	})

	t.Run("fails closed on cancel and path collisions", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "")

		// 1. No unattached local branches enters new-branch input and aborts cleanly on cancel.
		var stdout, stderr bytes.Buffer
		cancelNewBranchUI := interactiveUI{
			inputNewBranch: func(_ io.Writer) (string, error) {
				return "", gitcmd.ErrSelectionCanceled
			},
		}
		if err := runWithUI([]string{"add"}, defaultWT, cancelNewBranchUI, &stdout, &stderr); err == nil {
			t.Fatal("expected error when new-branch input is canceled, got nil")
		}

		runGit(t, defaultWT, "branch", "feat/a")
		runGit(t, defaultWT, "branch", "feat-a")
		runGit(t, defaultWT, "branch", "existing-dir")

		// 2. Selector cancel leaves worktree list untouched.
		cancelSelector := func(_, _ string, _ []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			return nil, errors.New("worktree addition canceled")
		}
		stdout.Reset()
		stderr.Reset()
		if err := runWithOptions([]string{"add", "--interactive"}, defaultWT, cancelSelector, &stdout, &stderr); err == nil {
			t.Fatal("expected error on cancel, got nil")
		}

		// 3. Flattened directory collision between feat/a and feat-a fails before creating any worktree.
		collideSelector := func(_, _ string, _ []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			return []string{"feat/a", "feat-a"}, nil
		}
		stdout.Reset()
		stderr.Reset()
		if err := runWithOptions([]string{"add", "--interactive"}, defaultWT, collideSelector, &stdout, &stderr); err == nil {
			t.Fatal("expected collision error, got nil")
		}
		if _, err := os.Stat(filepath.Join(repoDir, "feat-a")); !os.IsNotExist(err) {
			t.Errorf("expected no worktree created after collision error")
		}

		// 4. Existing target directory conflict aborts before creating any selected branch.
		if err := os.MkdirAll(filepath.Join(repoDir, "existing-dir"), 0o755); err != nil {
			t.Fatalf("mkdir existing-dir: %v", err)
		}
		existingDirSelector := func(_, _ string, _ []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			return []string{"feat/a", "existing-dir"}, nil
		}
		stdout.Reset()
		stderr.Reset()
		if err := runWithOptions([]string{"add", "--interactive"}, defaultWT, existingDirSelector, &stdout, &stderr); err == nil {
			t.Fatal("expected existing directory error, got nil")
		}
		if _, err := os.Stat(filepath.Join(repoDir, "feat-a")); !os.IsNotExist(err) {
			t.Errorf("expected feat-a not to be created when another selected branch conflicts")
		}
	})
}

func installFakeGum(t *testing.T, script string) string {
	t.Helper()
	binDir := t.TempDir()
	logPath := filepath.Join(binDir, "gum-args.log")
	gumPath := filepath.Join(binDir, "gum")
	content := "#!/bin/sh\nprintf '%s\\n' \"$*\" >> " + shellQuote(logPath) + "\n" + script + "\n"
	if err := os.WriteFile(gumPath, []byte(content), 0o755); err != nil {
		t.Fatalf("write fake gum: %v", err)
	}
	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))
	return logPath
}

func TestGumHelpersAndParsing(t *testing.T) {
	t.Run("parses fzf --expect output including empty match cases", func(t *testing.T) {
		cases := []struct {
			raw  string
			want selectChoice
		}{
			{raw: "\n/repo/main\n", want: selectChoice{Key: "", Path: "/repo/main"}},
			{raw: "ctrl-x\n/repo/feat\n", want: selectChoice{Key: "ctrl-x", Path: "/repo/feat"}},
			{raw: "ctrl-a\n\n", want: selectChoice{Key: "ctrl-a", Path: ""}},
			{raw: "ctrl-a\n", want: selectChoice{Key: "ctrl-a", Path: ""}},
			{raw: "", want: selectChoice{}},
		}
		for _, tc := range cases {
			if got := parseFzfSelectOutput(tc.raw); got != tc.want {
				t.Errorf("parseFzfSelectOutput(%q) = %+v, want %+v", tc.raw, got, tc.want)
			}
		}
	})

	t.Run("invokes gum choose, input, and confirm with expected args and exit handling", func(t *testing.T) {
		logPath := installFakeGum(t, `
case "$1" in
  choose)
    case "$*" in
      *"--header=Action for"*) echo "Remove worktree" ;;
      *"--header=Add worktree"*) echo "New branch" ;;
      *) exit 1 ;;
    esac
    ;;
  input)
    echo "  feat/from-gum  "
    ;;
  confirm)
    if [ "${GUM_CONFIRM_EXIT:-0}" -ne 0 ]; then
      exit "$GUM_CONFIRM_EXIT"
    fi
    ;;
esac
`)
		var stderr bytes.Buffer

		mode, err := chooseAddModeWithGum(&stderr)
		if err != nil || mode != addModeNew {
			t.Fatalf("chooseAddModeWithGum = (%v, %v), want (addModeNew, nil)", mode, err)
		}

		branch, err := inputNewBranchWithGum(&stderr)
		if err != nil || branch != "feat/from-gum" {
			t.Fatalf("inputNewBranchWithGum = (%q, %v), want (feat/from-gum, nil)", branch, err)
		}

		action, err := chooseWorktreeActionWithGum("main", "main", &stderr)
		if err != nil || action != actionRemove {
			t.Fatalf("chooseWorktreeActionWithGum = (%v, %v), want (actionRemove, nil)", action, err)
		}

		t.Setenv("GUM_CONFIRM_EXIT", "0")
		if ok, err := confirmDirenvAllowWithGum("feat-one", &stderr); err != nil || !ok {
			t.Fatalf("confirmDirenvAllowWithGum (yes) = (%v, %v), want (true, nil)", ok, err)
		}

		t.Setenv("GUM_CONFIRM_EXIT", "1")
		if ok, err := confirmDirenvAllowWithGum("feat-one", &stderr); err != nil || ok {
			t.Fatalf("confirmDirenvAllowWithGum (no) = (%v, %v), want (false, nil)", ok, err)
		}

		t.Setenv("GUM_CONFIRM_EXIT", "130")
		if ok, err := confirmRemoveWorktreeWithGum("feat-one", "feat/one", &stderr); !errors.Is(err, gitcmd.ErrSelectionCanceled) || ok {
			t.Fatalf("confirmRemoveWorktreeWithGum (cancel) = (%v, %v), want (false, ErrSelectionCanceled)", ok, err)
		}

		logged, err := os.ReadFile(logPath)
		if err != nil {
			t.Fatalf("read gum args log: %v", err)
		}
		if !strings.Contains(string(logged), "confirm --default=false Allow direnv in feat-one?") {
			t.Errorf("expected fail-closed --default=false in confirm args, got:\n%s", string(logged))
		}
	})
}

func TestRun_InteractiveNewBranchAndDirenvConfirm(t *testing.T) {
	t.Run("creates new branch worktree via interactive flow when no unattached branches exist", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "")

		var gotBaseOptions []string
		ui := interactiveUI{
			inputNewBranch: func(_ io.Writer) (string, error) {
				return "feat/interactive-new", nil
			},
			chooseBaseRef: func(branch string, baseOptions []string, _ string, _ io.Writer) (string, error) {
				if branch != "feat/interactive-new" {
					t.Errorf("branch passed to chooseBaseRef = %q", branch)
				}
				gotBaseOptions = append([]string(nil), baseOptions...)
				return baseOptions[0], nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runWithUI([]string{"add"}, defaultWT, ui, &stdout, &stderr); err != nil {
			t.Fatalf("interactive new-branch add failed: %v, stderr: %s", err, stderr.String())
		}

		wantWT := filepath.Join(repoDir, "feat-interactive-new")
		if got := strings.TrimSpace(stdout.String()); got != wantWT {
			t.Errorf("stdout = %q, want %q", got, wantWT)
		}
		if len(gotBaseOptions) < 2 || gotBaseOptions[0] != "origin/main" || gotBaseOptions[1] != "main" {
			t.Errorf("baseOptions = %v, want origin/main and main first", gotBaseOptions)
		}
		if br := runGit(t, wantWT, "symbolic-ref", "--short", "HEAD"); br != "feat/interactive-new" {
			t.Errorf("checked out branch = %q, want feat/interactive-new", br)
		}
		if cmd := exec.Command("git", "-C", wantWT, "rev-parse", "--abbrev-ref", "@{u}"); cmd.Run() == nil {
			t.Errorf("expected interactive new branch not to set upstream tracking")
		}
	})

	t.Run("prompts direnv allow in interactive mode and keeps fail-closed when declined", func(t *testing.T) {
		isolateEnv(t)
		_, defaultWT := setupCleanBareRepo(t, "main", nil, "export FROM_ENVRC=1\n")

		// 1. Declining confirmation keeps .envrc disallowed.
		confirmDeclineUI := interactiveUI{
			inputNewBranch: func(_ io.Writer) (string, error) { return "feat/deny-envrc", nil },
			chooseBaseRef: func(_ string, opts []string, _ string, _ io.Writer) (string, error) {
				return opts[0], nil
			},
			confirmDirenvAllow: func(_ string, _ io.Writer) (bool, error) { return false, nil },
		}
		var stdout, stderr bytes.Buffer
		if err := runWithUI([]string{"add"}, defaultWT, confirmDeclineUI, &stdout, &stderr); err != nil {
			t.Fatalf("add (decline envrc) failed: %v, stderr: %s", err, stderr.String())
		}
		deniedWT := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, deniedWT); state == 0 {
			t.Fatalf("expected .envrc NOT to be allowed when declined, got state=%d", state)
		}

		// 2. Accepting confirmation allows .envrc.
		confirmAcceptUI := interactiveUI{
			inputNewBranch: func(_ io.Writer) (string, error) { return "feat/allow-envrc", nil },
			chooseBaseRef: func(_ string, opts []string, _ string, _ io.Writer) (string, error) {
				return opts[0], nil
			},
			confirmDirenvAllow: func(_ string, _ io.Writer) (bool, error) { return true, nil },
		}
		stdout.Reset()
		stderr.Reset()
		if err := runWithUI([]string{"add"}, defaultWT, confirmAcceptUI, &stdout, &stderr); err != nil {
			t.Fatalf("add (accept envrc) failed: %v, stderr: %s", err, stderr.String())
		}
		allowedWT := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, allowedWT); state != 0 {
			t.Fatalf("expected .envrc to be allowed when confirmed, got state=%d", state)
		}
	})

	t.Run("select supports action menu, ctrl-a add, and safe ctrl-d removal", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "")

		// 1. ctrl-a opens add flow even with empty selection path and prints newly created worktree path.
		var stdout, stderr bytes.Buffer
		addFromSelectUI := interactiveUI{
			selectWorktree: func(_, _ string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-a", Path: ""}, nil
			},
			inputNewBranch: func(_ io.Writer) (string, error) { return "feat/from-select", nil },
			chooseBaseRef: func(_ string, opts []string, _ string, _ io.Writer) (string, error) {
				return opts[0], nil
			},
		}
		if err := runWithUI([]string{"select"}, defaultWT, addFromSelectUI, &stdout, &stderr); err != nil {
			t.Fatalf("select ctrl-a failed: %v, stderr: %s", err, stderr.String())
		}
		createdWT := filepath.Join(repoDir, "feat-from-select")
		if got := strings.TrimSpace(stdout.String()); got != createdWT {
			t.Errorf("select ctrl-a stdout = %q, want %q", got, createdWT)
		}

		// 2. ctrl-x -> actionSwitch prints selected worktree path.
		stdout.Reset()
		stderr.Reset()
		switchUI := interactiveUI{
			selectWorktree: func(_, _ string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-x", Path: createdWT}, nil
			},
			chooseWorktreeAction: func(_, _ string, _ io.Writer) (worktreeAction, error) {
				return actionSwitch, nil
			},
		}
		if err := runWithUI([]string{"select"}, defaultWT, switchUI, &stdout, &stderr); err != nil {
			t.Fatalf("select ctrl-x switch failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != createdWT {
			t.Errorf("select ctrl-x switch stdout = %q, want %q", got, createdWT)
		}

		// 3. ctrl-d refuses removing the current worktree.
		stdout.Reset()
		stderr.Reset()
		removeCurrentUI := interactiveUI{
			selectWorktree: func(_, _ string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-d", Path: defaultWT}, nil
			},
			confirmRemoveWorktree: func(_, _ string, _ io.Writer) (bool, error) {
				t.Fatal("confirmRemoveWorktree should not be called for current worktree")
				return false, nil
			},
		}
		if err := runWithUI([]string{"select"}, defaultWT, removeCurrentUI, &stdout, &stderr); err == nil {
			t.Fatal("expected error when removing current worktree")
		}

		// 4. ctrl-x -> actionRemove removes non-current worktree after confirmation and prints nothing to stdout.
		stdout.Reset()
		stderr.Reset()
		removeOtherUI := interactiveUI{
			selectWorktree: func(_, _ string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-x", Path: createdWT}, nil
			},
			chooseWorktreeAction: func(_, _ string, _ io.Writer) (worktreeAction, error) {
				return actionRemove, nil
			},
			confirmRemoveWorktree: func(_, _ string, _ io.Writer) (bool, error) {
				return true, nil
			},
		}
		if err := runWithUI([]string{"select"}, defaultWT, removeOtherUI, &stdout, &stderr); err != nil {
			t.Fatalf("select ctrl-x remove failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != "" {
			t.Errorf("expected empty stdout after worktree removal, got %q", got)
		}
		if _, err := os.Stat(createdWT); !os.IsNotExist(err) {
			t.Errorf("expected %s to be removed", createdWT)
		}
	})
}

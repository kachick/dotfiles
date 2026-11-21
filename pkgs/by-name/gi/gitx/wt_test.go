package main

import (
	"bytes"
	"errors"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

func setupCleanBareRepo(t *testing.T, defaultBranch string, remoteBranches []string, envrcContent string) (repoDir, defaultWT string) {
	t.Helper()
	temp := t.TempDir()
	seedDir := filepath.Join(temp, "seed")
	runGit(t, temp, "init", "-b", defaultBranch, seedDir)
	runGit(t, seedDir, "config", "user.name", "Tester")
	runGit(t, seedDir, "config", "user.email", "tester@example.com")

	writeTestFile(t, filepath.Join(seedDir, "README.md"), "hello\n")
	if envrcContent != "" {
		writeTestFile(t, filepath.Join(seedDir, ".envrc"), envrcContent)
	}
	runGit(t, seedDir, "add", ".")
	runGit(t, seedDir, "commit", "-m", "Initial commit")

	for _, br := range remoteBranches {
		runGit(t, seedDir, "checkout", "-b", br)
		marker := filepath.Join(seedDir, strings.ReplaceAll(br, "/", "-")+".txt")
		writeTestFile(t, marker, br+"\n")
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

	for _, br := range remoteBranches {
		runGit(t, repoDir, "branch", "-D", br)
	}
	return repoDir, defaultWT
}

func TestRunGitx_RecoversDeletedWorkDir(t *testing.T) {
	isolateEnv(t)
	repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "")

	removedWT := filepath.Join(repoDir, "removed")
	runGit(t, repoDir, "worktree", "add", "-b", "removed", removedWT, "main")
	t.Chdir(removedWT)
	t.Setenv("PWD", removedWT)
	runGit(t, repoDir, "worktree", "remove", removedWT)

	var stdout, stderr bytes.Buffer
	if err := runGitx([]string{"wt", "path"}, strings.NewReader(""), &stdout, &stderr); err != nil {
		t.Fatalf("wt path from deleted directory failed: %v, stderr: %s", err, stderr.String())
	}
	if got := strings.TrimSpace(stdout.String()); got != defaultWT {
		t.Errorf("stdout = %q, want %q", got, defaultWT)
	}
	if !strings.Contains(stderr.String(), repoDir) {
		t.Errorf("stderr should mention fallback directory %q, got %q", repoDir, stderr.String())
	}
}

func TestRunWT_AddListPath(t *testing.T) {
	t.Run("creates worktrees for new, local, and remote branches with flat slash sanitization", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/remote-one"}, "")

		runGit(t, defaultWT, "branch", "local-only")

		var stdout, stderr bytes.Buffer
		if err := runWT([]string{"add", "--branch", "feat/new-one"}, defaultWT, &stdout, &stderr); err != nil {
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
		if cmd := exec.Command("git", "-C", gotNew, "rev-parse", "--abbrev-ref", "@{u}"); cmd.Run() == nil {
			t.Errorf("expected new branch not to have an upstream tracking branch")
		}

		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"add", "--branch", "feat/new-one"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("idempotent add failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != wantNew {
			t.Errorf("idempotent stdout = %q, want %q", got, wantNew)
		}

		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"add", "--branch", "local-only"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add local branch failed: %v, stderr: %s", err, stderr.String())
		}
		wantLocal := filepath.Join(repoDir, "local-only")
		if got := strings.TrimSpace(stdout.String()); got != wantLocal {
			t.Errorf("local worktree path = %q, want %q", got, wantLocal)
		}

		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"add", "--branch", "feat/remote-one"}, defaultWT, &stdout, &stderr); err != nil {
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

		stdout.Reset()
		stderr.Reset()
		if err := runWT(nil, wantRemote, &stdout, &stderr); err != nil {
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

		stdout.Reset()
		if err := runWT([]string{"path"}, wantRemote, &stdout, &stderr); err != nil {
			t.Fatalf("path (default) failed: %v", err)
		}
		if got := strings.TrimSpace(stdout.String()); got != defaultWT {
			t.Errorf("path (default) = %q, want %q", got, defaultWT)
		}

		stdout.Reset()
		if err := runWT([]string{"path", "feat/new-one"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("path by branch failed: %v", err)
		}
		if got := strings.TrimSpace(stdout.String()); got != wantNew {
			t.Errorf("path by branch = %q, want %q", got, wantNew)
		}

		stdout.Reset()
		if err := runWT([]string{"path", "feat-remote-one"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("path by dir name failed: %v", err)
		}
		if got := strings.TrimSpace(stdout.String()); got != wantRemote {
			t.Errorf("path by dir name = %q, want %q", got, wantRemote)
		}
	})

	t.Run("detects non-main default branch dynamically and honors --base", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "trunk", nil, "")

		var stdout, stderr bytes.Buffer
		if err := runWT([]string{"add", "--branch", "topic-from-trunk"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add on trunk repo failed: %v, stderr: %s", err, stderr.String())
		}
		topicWT := strings.TrimSpace(stdout.String())
		trunkHash := runGit(t, defaultWT, "rev-parse", "HEAD")
		topicHash := runGit(t, topicWT, "rev-parse", "HEAD")
		if topicHash != trunkHash {
			t.Errorf("topic HEAD = %s, want trunk %s", topicHash, trunkHash)
		}

		writeTestFile(t, filepath.Join(topicWT, "base.txt"), "base\n")
		runGit(t, topicWT, "config", "user.name", "Tester")
		runGit(t, topicWT, "config", "user.email", "tester@example.com")
		runGit(t, topicWT, "add", "base.txt")
		runGit(t, topicWT, "commit", "-m", "Base commit")
		baseHash := runGit(t, topicWT, "rev-parse", "HEAD")
		runGit(t, repoDir, "update-ref", "refs/remotes/origin/trunk", baseHash)

		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"add", "--branch", "from-origin-trunk"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add from origin/trunk failed: %v, stderr: %s", err, stderr.String())
		}
		originTopicWT := strings.TrimSpace(stdout.String())
		if got := runGit(t, originTopicWT, "rev-parse", "HEAD"); got != baseHash {
			t.Errorf("from-origin-trunk HEAD = %s, want origin/trunk %s", got, baseHash)
		}

		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"default-branch"}, originTopicWT, &stdout, &stderr); err != nil {
			t.Fatalf("default-branch failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != "trunk" {
			t.Errorf("default-branch = %q, want trunk", got)
		}

		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"add", "--base", "topic-from-trunk", "--branch", "child-topic"}, defaultWT, &stdout, &stderr); err != nil {
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

		tamperWT := filepath.Join(t.TempDir(), "tamper")
		runGit(t, defaultWT, "worktree", "add", "--track", "-b", "feat/tampered", tamperWT, "origin/feat/tampered")
		runGit(t, tamperWT, "config", "user.name", "Attacker")
		runGit(t, tamperWT, "config", "user.email", "attacker@example.com")
		writeTestFile(t, filepath.Join(tamperWT, ".envrc"), "export EVIL_VAR=1\n")
		runGit(t, tamperWT, "add", ".envrc")
		runGit(t, tamperWT, "commit", "-m", "Modify .envrc")
		runGit(t, tamperWT, "update-ref", "refs/remotes/origin/feat/tampered", "HEAD")
		runGit(t, defaultWT, "worktree", "remove", tamperWT)
		runGit(t, defaultWT, "branch", "-D", "feat/tampered")

		var stdout, stderr bytes.Buffer
		if err := runWT([]string{"add", "--branch", "untrusted-repo-wt"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add untrusted failed: %v, stderr: %s", err, stderr.String())
		}
		untrustedWT := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, untrustedWT); state == 0 {
			t.Fatalf("expected .envrc NOT to be allowed in untrusted repo, got state=%d", state)
		}

		runDirenvAllow(t, defaultWT)

		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"add", "--branch", "trusted-wt"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add trusted failed: %v, stderr: %s", err, stderr.String())
		}
		trustedWT := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, trustedWT); state != 0 {
			t.Fatalf("expected identical .envrc to be auto-allowed, got state=%d", state)
		}

		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"add", "--branch", "feat/tampered"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add tampered failed: %v, stderr: %s", err, stderr.String())
		}
		tamperedWT := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, tamperedWT); state == 0 {
			t.Fatalf("expected modified .envrc NOT to be auto-allowed, got state=%d", state)
		}

		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"add", "--trust", "--branch", "feat/tampered"}, defaultWT, &stdout, &stderr); err != nil {
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
		writeTestFile(t, filepath.Join(legacyDir, "README.md"), "hi\n")
		runGit(t, legacyDir, "add", ".")
		runGit(t, legacyDir, "commit", "-m", "init")

		var stdout, stderr bytes.Buffer
		err := runWT([]string{"add", "--branch", "feat-x"}, legacyDir, &stdout, &stderr)
		if err == nil {
			t.Fatal("expected add on non-bare repo to fail, got nil")
		}

		runGit(t, legacyDir, "checkout", "-b", "feat-current")
		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"default-branch"}, legacyDir, &stdout, &stderr); err != nil {
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
		if err := runWT([]string{"add", "--branch", "feat/preview"}, defaultWT, &listOut, &stderr); err != nil {
			t.Fatalf("add feat/preview failed: %v, stderr: %s", err, stderr.String())
		}
		previewWT := strings.TrimSpace(listOut.String())

		var previewOut bytes.Buffer
		if err := runWT([]string{"_preview", previewWT}, repoDir, &previewOut, &stderr); err != nil {
			t.Fatalf("_preview failed: %v, stderr: %s", err, stderr.String())
		}
		previewText := previewOut.String()
		for _, want := range []string{"feat/preview", "Commit on feat/preview"} {
			if !strings.Contains(previewText, want) {
				t.Errorf("expected preview output to contain %q, got:\n%s", want, previewText)
			}
		}

		listOut.Reset()
		if err := runWT([]string{"list"}, defaultWT, &listOut, &stderr); err != nil {
			t.Fatalf("list failed: %v", err)
		}
		filterArgs := append([]string{"--filter=feat-preview"}, wtFzfSelectArgs("gitx", "")...)
		fzfCmd := exec.Command("fzf", filterArgs...)
		fzfCmd.Stdin = strings.NewReader(listOut.String())
		fzfOut, err := fzfCmd.Output()
		if err != nil {
			t.Fatalf("fzf --filter with wtFzfSelectArgs failed: %v", err)
		}
		lines := strings.Split(strings.TrimSpace(string(fzfOut)), "\n")
		if len(lines) != 2 || lines[0] != "feat-preview" || lines[1] != previewWT {
			t.Errorf("fzf output lines = %q, want [feat-preview %q]", lines, previewWT)
		}
	})

	t.Run("works from clean-bare root and worktrees when invoked with inherited GIT_DIR from git alias", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "trunk", []string{"feat/one"}, "")

		t.Setenv("GIT_DIR", ".git")
		var stdout, stderr bytes.Buffer
		if err := runWT([]string{"default-branch"}, repoDir, &stdout, &stderr); err != nil {
			t.Fatalf("default-branch from bare root with GIT_DIR=.git failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != "trunk" {
			t.Errorf("default-branch = %q, want trunk", got)
		}

		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"list"}, repoDir, &stdout, &stderr); err != nil {
			t.Fatalf("list from bare root with GIT_DIR=.git failed: %v, stderr: %s", err, stderr.String())
		}
		if !strings.Contains(stdout.String(), defaultWT) {
			t.Errorf("expected list output to include %q, got:\n%s", defaultWT, stdout.String())
		}

		t.Setenv("GIT_DIR", filepath.Join(repoDir, ".git", "worktrees", "trunk"))
		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"default-branch"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("default-branch from worktree with worktree GIT_DIR failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != "trunk" {
			t.Errorf("default-branch = %q, want trunk", got)
		}
	})
}

func TestRunWT_AddInteractive(t *testing.T) {
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
			if err := runWT(args, defaultWT, &stdout, &stderr); err == nil {
				t.Errorf("expected error for args %v, got nil", args)
			}
		}
	})

	t.Run("defaults bare add to interactive mode, excludes checked-out branches, propagates direnv trust, and prints single cd target", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "export SHARED=1\n")

		tmpWT := filepath.Join(t.TempDir(), "tmp-same")
		runGit(t, defaultWT, "worktree", "add", "-b", "feat/same-envrc", tmpWT, "main")
		runGit(t, tmpWT, "config", "user.name", "Tester")
		runGit(t, tmpWT, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(tmpWT, "same.txt"), "same\n")
		runGit(t, tmpWT, "add", "same.txt")
		runGit(t, tmpWT, "commit", "-m", "Same envrc")
		runGit(t, defaultWT, "worktree", "remove", tmpWT)

		tamperWT := filepath.Join(t.TempDir(), "tmp-tamper")
		runGit(t, defaultWT, "worktree", "add", "-b", "feat/tampered-envrc", tamperWT, "main")
		runGit(t, tamperWT, "config", "user.name", "Tester")
		runGit(t, tamperWT, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(tamperWT, ".envrc"), "export EVIL=1\n")
		runGit(t, tamperWT, "add", ".envrc")
		runGit(t, tamperWT, "commit", "-m", "Tampered envrc")
		runGit(t, defaultWT, "worktree", "remove", tamperWT)

		runGit(t, defaultWT, "branch", "topic-unpicked")
		runDirenvAllow(t, defaultWT)

		var gotCandidateNames []string
		selector := func(_, _ string, candidates []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			for _, c := range candidates {
				gotCandidateNames = append(gotCandidateNames, c.Name)
			}
			return []string{"feat/same-envrc", "feat/tampered-envrc"}, nil
		}

		var stdout, stderr bytes.Buffer
		if err := runWTWithOptions([]string{"add"}, defaultWT, selector, &stdout, &stderr); err != nil {
			t.Fatalf("add (default interactive) failed: %v, stderr: %s", err, stderr.String())
		}

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

		var stdout, stderr bytes.Buffer
		if err := runWT([]string{"add", "--branch", "topic-a"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("add topic-a failed: %v", err)
		}
		topicAWT := strings.TrimSpace(stdout.String())
		runGit(t, repoDir, "worktree", "remove", defaultWT)

		selector := func(_, _ string, _ []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			return []string{"topic-b", "main"}, nil
		}
		stdout.Reset()
		stderr.Reset()
		if err := runWTWithOptions([]string{"add", "--interactive"}, topicAWT, selector, &stdout, &stderr); err != nil {
			t.Fatalf("interactive add failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != defaultWT {
			t.Errorf("stdout = %q, want default branch worktree %q", got, defaultWT)
		}

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
		writeTestFile(t, filepath.Join(tmpWT, "note.txt"), "note\n")
		runGit(t, tmpWT, "add", "note.txt")
		runGit(t, tmpWT, "commit", "-m", "Previewable branch commit")
		runGit(t, defaultWT, "worktree", "remove", tmpWT)

		var previewOut, stderr bytes.Buffer
		if err := runWT([]string{"_preview-branch", repoDir, "main", "feat/branch-preview"}, repoDir, &previewOut, &stderr); err != nil {
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
		filterArgs := append([]string{"--filter=feat/branch-preview"}, wtFzfAddArgs("gitx", repoDir, "main")...)
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

		var stdout, stderr bytes.Buffer
		cancelNewBranchUI := wtInteractiveUI{
			inputNewBranch: func(_ io.Writer) (string, error) {
				return "", gitcmd.ErrSelectionCanceled
			},
		}
		if err := runWTWithUI([]string{"add"}, defaultWT, cancelNewBranchUI, &stdout, &stderr); err == nil {
			t.Fatal("expected error when new-branch input is canceled, got nil")
		}

		runGit(t, defaultWT, "branch", "feat/a")
		runGit(t, defaultWT, "branch", "feat-a")
		runGit(t, defaultWT, "branch", "existing-dir")

		cancelSelector := func(_, _ string, _ []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			return nil, errors.New("worktree addition canceled")
		}
		stdout.Reset()
		stderr.Reset()
		if err := runWTWithOptions([]string{"add", "--interactive"}, defaultWT, cancelSelector, &stdout, &stderr); err == nil {
			t.Fatal("expected error on cancel, got nil")
		}

		collideSelector := func(_, _ string, _ []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			return []string{"feat/a", "feat-a"}, nil
		}
		stdout.Reset()
		stderr.Reset()
		if err := runWTWithOptions([]string{"add", "--interactive"}, defaultWT, collideSelector, &stdout, &stderr); err == nil {
			t.Fatal("expected collision error, got nil")
		}
		if _, err := os.Stat(filepath.Join(repoDir, "feat-a")); !os.IsNotExist(err) {
			t.Errorf("expected no worktree created after collision error")
		}

		if err := os.MkdirAll(filepath.Join(repoDir, "existing-dir"), 0o755); err != nil {
			t.Fatalf("mkdir existing-dir: %v", err)
		}
		existingDirSelector := func(_, _ string, _ []gitcmd.BranchCandidate, _ io.Writer) ([]string, error) {
			return []string{"feat/a", "existing-dir"}, nil
		}
		stdout.Reset()
		stderr.Reset()
		if err := runWTWithOptions([]string{"add", "--interactive"}, defaultWT, existingDirSelector, &stdout, &stderr); err == nil {
			t.Fatal("expected existing directory error, got nil")
		}
		if _, err := os.Stat(filepath.Join(repoDir, "feat-a")); !os.IsNotExist(err) {
			t.Errorf("expected feat-a not to be created when another selected branch conflicts")
		}
	})
}

func installFakeTool(t *testing.T, name, script string) string {
	t.Helper()
	binDir := t.TempDir()
	logPath := filepath.Join(binDir, name+"-args.log")
	toolPath := filepath.Join(binDir, name)
	content := "#!/bin/sh\nprintf '%s\\n' \"$*\" >> " + shellQuote(logPath) + "\n" + script + "\n"
	if err := os.WriteFile(toolPath, []byte(content), 0o755); err != nil {
		t.Fatalf("write fake %s: %v", name, err)
	}
	t.Setenv("PATH", binDir+":"+os.Getenv("PATH"))
	return logPath
}

func installFakeGum(t *testing.T, script string) string {
	return installFakeTool(t, "gum", script)
}

func TestGumHelpersAndParsing(t *testing.T) {
	t.Run("parses fzf --print-query --expect output including unmatched query cases", func(t *testing.T) {
		cases := []struct {
			raw  string
			want selectChoice
		}{
			{raw: "\n\n/repo/main\n", want: selectChoice{Query: "", Key: "", Path: "/repo/main"}},
			{raw: "feat\nctrl-x\n/repo/feat\n", want: selectChoice{Query: "feat", Key: "ctrl-x", Path: "/repo/feat"}},
			{raw: "new-br\n\n\n", want: selectChoice{Query: "new-br", Key: "", Path: ""}},
			{raw: "new-br\n", want: selectChoice{Query: "new-br", Key: "", Path: ""}},
			{raw: "\nctrl-a\n\n", want: selectChoice{Query: "", Key: "ctrl-a", Path: ""}},
			{raw: "\nctrl-a\n", want: selectChoice{Query: "", Key: "ctrl-a", Path: ""}},
			{raw: "", want: selectChoice{}},
		}
		for _, tc := range cases {
			if got := parseFzfSelectOutput(tc.raw); got != tc.want {
				t.Errorf("parseFzfSelectOutput(%q) = %+v, want %+v", tc.raw, got, tc.want)
			}
		}
	})

	t.Run("distinguishes unmatched fzf exit 1 with query from cancel exit 130", func(t *testing.T) {
		installFakeTool(t, "fzf", `
printf '%s' "${FAKE_FZF_OUT:-}"
exit "${FAKE_FZF_EXIT:-0}"
`)
		var stderr bytes.Buffer

		t.Setenv("FAKE_FZF_OUT", "feat/new-one\n\n")
		t.Setenv("FAKE_FZF_EXIT", "1")
		got, err := selectWorktreeWithFzf("gitx", "", strings.NewReader("main\tmain\t/repo/main\n"), &stderr)
		if err != nil {
			t.Fatalf("expected unmatched query on exit 1 to succeed, got %v", err)
		}
		if got.Query != "feat/new-one" || got.Path != "" {
			t.Errorf("got = %+v, want Query=feat/new-one Path=\"\"", got)
		}

		t.Setenv("FAKE_FZF_OUT", "\n\n")
		t.Setenv("FAKE_FZF_EXIT", "1")
		if _, err := selectWorktreeWithFzf("gitx", "", strings.NewReader("main\tmain\t/repo/main\n"), &stderr); !errors.Is(err, gitcmd.ErrSelectionCanceled) {
			t.Fatalf("expected empty exit 1 to cancel, got %v", err)
		}

		t.Setenv("FAKE_FZF_OUT", "feat/aborted\n\n")
		t.Setenv("FAKE_FZF_EXIT", "130")
		if _, err := selectWorktreeWithFzf("gitx", "", strings.NewReader("main\tmain\t/repo/main\n"), &stderr); !errors.Is(err, gitcmd.ErrSelectionCanceled) {
			t.Fatalf("expected exit 130 to cancel even with query, got %v", err)
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

func TestRunWT_InteractiveNewBranchAndDirenvConfirm(t *testing.T) {
	t.Run("creates new branch worktree via interactive flow when no unattached branches exist", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "")

		var gotBaseOptions []string
		ui := wtInteractiveUI{
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
		if err := runWTWithUI([]string{"add"}, defaultWT, ui, &stdout, &stderr); err != nil {
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

		confirmDeclineUI := wtInteractiveUI{
			inputNewBranch: func(_ io.Writer) (string, error) { return "feat/deny-envrc", nil },
			chooseBaseRef: func(_ string, opts []string, _ string, _ io.Writer) (string, error) {
				return opts[0], nil
			},
			confirmDirenvAllow: func(_ string, _ io.Writer) (bool, error) { return false, nil },
		}
		var stdout, stderr bytes.Buffer
		if err := runWTWithUI([]string{"add"}, defaultWT, confirmDeclineUI, &stdout, &stderr); err != nil {
			t.Fatalf("add (decline envrc) failed: %v, stderr: %s", err, stderr.String())
		}
		deniedWT := strings.TrimSpace(stdout.String())
		if state := direnvAllowedState(t, deniedWT); state == 0 {
			t.Fatalf("expected .envrc NOT to be allowed when declined, got state=%d", state)
		}

		confirmAcceptUI := wtInteractiveUI{
			inputNewBranch: func(_ io.Writer) (string, error) { return "feat/allow-envrc", nil },
			chooseBaseRef: func(_ string, opts []string, _ string, _ io.Writer) (string, error) {
				return opts[0], nil
			},
			confirmDirenvAllow: func(_ string, _ io.Writer) (bool, error) { return true, nil },
		}
		stdout.Reset()
		stderr.Reset()
		if err := runWTWithUI([]string{"add"}, defaultWT, confirmAcceptUI, &stdout, &stderr); err != nil {
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

		var stdout, stderr bytes.Buffer
		addFromSelectUI := wtInteractiveUI{
			selectWorktree: func(_, _ string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-a", Path: ""}, nil
			},
			inputNewBranch: func(_ io.Writer) (string, error) { return "feat/from-select", nil },
			chooseBaseRef: func(_ string, opts []string, _ string, _ io.Writer) (string, error) {
				return opts[0], nil
			},
		}
		if err := runWTWithUI([]string{"select"}, defaultWT, addFromSelectUI, &stdout, &stderr); err != nil {
			t.Fatalf("select ctrl-a failed: %v, stderr: %s", err, stderr.String())
		}
		createdWT := filepath.Join(repoDir, "feat-from-select")
		if got := strings.TrimSpace(stdout.String()); got != createdWT {
			t.Errorf("select ctrl-a stdout = %q, want %q", got, createdWT)
		}

		stdout.Reset()
		stderr.Reset()
		switchUI := wtInteractiveUI{
			selectWorktree: func(_, _ string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-x", Path: createdWT}, nil
			},
			chooseWorktreeAction: func(_, _ string, _ io.Writer) (worktreeAction, error) {
				return actionSwitch, nil
			},
		}
		if err := runWTWithUI([]string{"select"}, defaultWT, switchUI, &stdout, &stderr); err != nil {
			t.Fatalf("select ctrl-x switch failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != createdWT {
			t.Errorf("select ctrl-x switch stdout = %q, want %q", got, createdWT)
		}

		stdout.Reset()
		stderr.Reset()
		removeCurrentUI := wtInteractiveUI{
			selectWorktree: func(_, _ string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-d", Path: defaultWT}, nil
			},
			confirmRemoveWorktree: func(_, _ string, _ io.Writer) (bool, error) {
				t.Fatal("confirmRemoveWorktree should not be called for current worktree")
				return false, nil
			},
		}
		if err := runWTWithUI([]string{"select"}, defaultWT, removeCurrentUI, &stdout, &stderr); err == nil {
			t.Fatal("expected error when removing current worktree")
		}

		stdout.Reset()
		stderr.Reset()
		removeOtherUI := wtInteractiveUI{
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
		if err := runWTWithUI([]string{"select"}, defaultWT, removeOtherUI, &stdout, &stderr); err != nil {
			t.Fatalf("select ctrl-x remove failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != "" {
			t.Errorf("expected empty stdout after worktree removal, got %q", got)
		}
		if _, err := os.Stat(createdWT); !os.IsNotExist(err) {
			t.Errorf("expected %s to be removed", createdWT)
		}

		// Refuses to remove the default branch worktree even when triggered from another worktree
		// or when the default worktree directory is temporarily on another branch.
		if err := runWTWithUI([]string{"add", "--branch", "feat/other-wt"}, defaultWT, wtInteractiveUI{}, &stdout, &stderr); err != nil {
			t.Fatalf("add feat/other-wt failed: %v", err)
		}
		otherWT := filepath.Join(repoDir, "feat-other-wt")
		removeDefaultFromOtherUI := wtInteractiveUI{
			selectWorktree: func(_, _ string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-d", Path: defaultWT}, nil
			},
			confirmRemoveWorktree: func(_, _ string, _ io.Writer) (bool, error) {
				t.Fatal("confirmRemoveWorktree should not be called for default worktree")
				return false, nil
			},
		}
		stdout.Reset()
		stderr.Reset()
		if err := runWTWithUI([]string{"select"}, otherWT, removeDefaultFromOtherUI, &stdout, &stderr); err == nil {
			t.Fatal("expected error when removing default worktree from another worktree")
		}
		if _, err := os.Stat(defaultWT); err != nil {
			t.Errorf("expected default worktree %s to remain intact: %v", defaultWT, err)
		}

		runGit(t, defaultWT, "switch", "-c", "feat/misplaced-in-main")
		stdout.Reset()
		stderr.Reset()
		if err := runWTWithUI([]string{"select"}, otherWT, removeDefaultFromOtherUI, &stdout, &stderr); err == nil {
			t.Fatal("expected error when removing clean-bare default worktree path even on another branch")
		}
		if _, err := os.Stat(defaultWT); err != nil {
			t.Errorf("expected clean-bare default worktree path %s to remain intact: %v", defaultWT, err)
		}
	})
}

func TestRunWT_UnmatchedQueryAndCdHelper(t *testing.T) {
	t.Run("confirms before creating worktree from unmatched select query for new and existing branches", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/remote-hit"}, "export SAFE=1\n")

		var stdout, stderr bytes.Buffer
		declinedUI := wtInteractiveUI{
			selectWorktree: func(_, _ string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Query: "typo-br"}, nil
			},
			confirmCreateWorktree: func(branch string, _ io.Writer) (bool, error) {
				if branch != "typo-br" {
					t.Errorf("confirmCreateWorktree branch = %q, want typo-br", branch)
				}
				return false, nil
			},
		}
		if err := runWTWithUI([]string{"select"}, defaultWT, declinedUI, &stdout, &stderr); err != nil {
			t.Fatalf("declined unmatched query failed: %v", err)
		}
		if got := strings.TrimSpace(stdout.String()); got != "" {
			t.Errorf("expected empty stdout when declined, got %q", got)
		}
		if _, err := os.Stat(filepath.Join(repoDir, "typo-br")); !os.IsNotExist(err) {
			t.Errorf("expected declined branch worktree not to be created")
		}

		stdout.Reset()
		stderr.Reset()
		remoteUI := wtInteractiveUI{
			selectWorktree: func(_, _ string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Query: "feat/remote-hit"}, nil
			},
			confirmCreateWorktree: func(_ string, _ io.Writer) (bool, error) { return true, nil },
			chooseBaseRef: func(_ string, _ []string, _ string, _ io.Writer) (string, error) {
				t.Fatal("chooseBaseRef should not be called when origin branch already exists")
				return "", nil
			},
			confirmDirenvAllow: func(_ string, _ io.Writer) (bool, error) { return true, nil },
		}
		if err := runWTWithUI([]string{"select"}, defaultWT, remoteUI, &stdout, &stderr); err != nil {
			t.Fatalf("remote unmatched query failed: %v, stderr: %s", err, stderr.String())
		}
		wantRemoteWT := filepath.Join(repoDir, "feat-remote-hit")
		if got := strings.TrimSpace(stdout.String()); got != wantRemoteWT {
			t.Errorf("stdout = %q, want %q", got, wantRemoteWT)
		}
		if state := direnvAllowedState(t, wantRemoteWT); state != 0 {
			t.Errorf("expected .envrc to be allowed after confirmation, got state=%d", state)
		}

		stdout.Reset()
		stderr.Reset()
		newBranchUI := wtInteractiveUI{
			selectWorktree: func(_, _ string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Query: "feat/query-new"}, nil
			},
			confirmCreateWorktree: func(_ string, _ io.Writer) (bool, error) { return true, nil },
			chooseBaseRef: func(branch string, opts []string, _ string, _ io.Writer) (string, error) {
				if branch != "feat/query-new" {
					t.Errorf("chooseBaseRef branch = %q, want feat/query-new", branch)
				}
				return opts[0], nil
			},
			confirmDirenvAllow: func(_ string, _ io.Writer) (bool, error) { return false, nil },
		}
		if err := runWTWithUI([]string{"select"}, defaultWT, newBranchUI, &stdout, &stderr); err != nil {
			t.Fatalf("new branch unmatched query failed: %v, stderr: %s", err, stderr.String())
		}
		wantNewWT := filepath.Join(repoDir, "feat-query-new")
		if got := strings.TrimSpace(stdout.String()); got != wantNewWT {
			t.Errorf("stdout = %q, want %q", got, wantNewWT)
		}
		if br := runGit(t, wantNewWT, "symbolic-ref", "--short", "HEAD"); br != "feat/query-new" {
			t.Errorf("branch = %q, want feat/query-new", br)
		}
	})

	t.Run("_cd-helper dispatches cd commands, passes queries, and rejects non-cd wt or gitx subcommands", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "")

		var stdout, stderr bytes.Buffer
		if err := runWTWithUI([]string{"_cd-helper", "add", "--branch", "feat/via-helper"}, defaultWT, wtInteractiveUI{}, &stdout, &stderr); err != nil {
			t.Fatalf("_cd-helper add failed: %v, stderr: %s", err, stderr.String())
		}
		wantAdded := filepath.Join(repoDir, "feat-via-helper")
		if got := strings.TrimSpace(stdout.String()); got != wantAdded {
			t.Errorf("_cd-helper add stdout = %q, want %q", got, wantAdded)
		}

		stdout.Reset()
		stderr.Reset()
		if err := runWTWithUI([]string{"_cd-helper", "path", "feat/via-helper"}, defaultWT, wtInteractiveUI{}, &stdout, &stderr); err != nil {
			t.Fatalf("_cd-helper path failed: %v", err)
		}
		if got := strings.TrimSpace(stdout.String()); got != wantAdded {
			t.Errorf("_cd-helper path stdout = %q, want %q", got, wantAdded)
		}

		stdout.Reset()
		stderr.Reset()
		var gotQuery string
		queryUI := wtInteractiveUI{
			selectWorktree: func(_, query string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				gotQuery = query
				return selectChoice{Path: defaultWT}, nil
			},
		}
		if err := runWTWithUI([]string{"_cd-helper", "feat/via-helper"}, defaultWT, queryUI, &stdout, &stderr); err != nil {
			t.Fatalf("_cd-helper query failed: %v", err)
		}
		if gotQuery != "feat/via-helper" || strings.TrimSpace(stdout.String()) != defaultWT {
			t.Errorf("gotQuery=%q stdout=%q", gotQuery, stdout.String())
		}

		for _, cmd := range allWTSubcommands() {
			if cmd.outputsTarget {
				continue
			}
			stdout.Reset()
			stderr.Reset()
			if err := runWTWithUI([]string{"_cd-helper", cmd.name}, defaultWT, wtInteractiveUI{}, &stdout, &stderr); err == nil {
				t.Errorf("expected _cd-helper %q to fail, got nil", cmd.name)
			}
		}

		for _, cmd := range allGitxSubcommands() {
			stdout.Reset()
			stderr.Reset()
			if err := runWTWithUI([]string{"_cd-helper", cmd.name}, defaultWT, wtInteractiveUI{}, &stdout, &stderr); err == nil {
				t.Errorf("expected _cd-helper with gitx subcommand %q to fail, got nil", cmd.name)
			}
		}
	})
}

package main

import (
	"bytes"
	"errors"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRunWT_Promote(t *testing.T) {
	t.Run("moves checked-out branch from default worktree into its own flat worktree", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"fix/pr-review"}, "")

		// Simulate `gh pr checkout` switching the default worktree onto a PR branch.
		runGit(t, defaultWT, "switch", "--track", "-c", "fix/pr-review", "origin/fix/pr-review")

		var stdout, stderr bytes.Buffer
		if err := runWT([]string{"promote"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("wt promote failed: %v, stderr: %s", err, stderr.String())
		}

		wantDir := filepath.Join(repoDir, "fix-pr-review")
		if got := strings.TrimSpace(stdout.String()); got != wantDir {
			t.Fatalf("stdout = %q, want %q", got, wantDir)
		}
		if br := runGit(t, defaultWT, "symbolic-ref", "--short", "HEAD"); br != "main" {
			t.Errorf("default worktree branch = %q, want main", br)
		}
		if br := runGit(t, wantDir, "symbolic-ref", "--short", "HEAD"); br != "fix/pr-review" {
			t.Errorf("promoted worktree branch = %q, want fix/pr-review", br)
		}
	})

	t.Run("is idempotent when already in the branch's own flat worktree", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/topic"}, "")

		var stdout, stderr bytes.Buffer
		if err := runWT([]string{"add", "--branch", "feat/topic"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("wt add failed: %v", err)
		}
		topicWT := filepath.Join(repoDir, "feat-topic")

		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"promote"}, topicWT, &stdout, &stderr); err != nil {
			t.Fatalf("idempotent wt promote failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != topicWT {
			t.Errorf("stdout = %q, want %q", got, topicWT)
		}
	})

	t.Run("fails closed on uncommitted changes without switching branches", func(t *testing.T) {
		isolateEnv(t)
		_, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/dirty"}, "")
		runGit(t, defaultWT, "switch", "--track", "-c", "feat/dirty", "origin/feat/dirty")
		writeTestFile(t, filepath.Join(defaultWT, "untracked.txt"), "dirty\n")

		var stdout, stderr bytes.Buffer
		err := runWT([]string{"promote"}, defaultWT, &stdout, &stderr)
		if err == nil || !strings.Contains(err.Error(), "uncommitted changes") {
			t.Fatalf("expected uncommitted changes error, got %v", err)
		}
		if br := runGit(t, defaultWT, "symbolic-ref", "--short", "HEAD"); br != "feat/dirty" {
			t.Errorf("branch changed despite failure: got %q, want feat/dirty", br)
		}
	})

	t.Run("fails closed on default branch, detached HEAD, or when default branch is checked out elsewhere", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/one", "feat/two"}, "")

		var stdout, stderr bytes.Buffer
		if err := runWT([]string{"promote"}, defaultWT, &stdout, &stderr); err == nil || !strings.Contains(err.Error(), "already on default branch") {
			t.Fatalf("expected already-on-default error, got %v", err)
		}

		// Create feat/one worktree, switch it to feat/two while main is still checked out in defaultWT.
		if err := runWT([]string{"add", "--branch", "feat/one"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("wt add feat/one failed: %v", err)
		}
		oneWT := filepath.Join(repoDir, "feat-one")
		runGit(t, oneWT, "switch", "--track", "-c", "feat/two", "origin/feat/two")

		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"promote"}, oneWT, &stdout, &stderr); err == nil || !strings.Contains(err.Error(), "already checked out") {
			t.Fatalf("expected default-branch-checked-out error, got %v", err)
		}

		runGit(t, oneWT, "switch", "--detach", "HEAD")
		stdout.Reset()
		stderr.Reset()
		if err := runWT([]string{"promote"}, oneWT, &stdout, &stderr); err == nil || !strings.Contains(err.Error(), "detached") {
			t.Fatalf("expected detached HEAD error, got %v", err)
		}
	})

	t.Run("rejects non-clean-bare repositories", func(t *testing.T) {
		isolateEnv(t)
		dir := t.TempDir()
		runGit(t, dir, "init", "-b", "main")
		runGit(t, dir, "config", "user.name", "Tester")
		runGit(t, dir, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(dir, "README.md"), "hi\n")
		runGit(t, dir, "add", ".")
		runGit(t, dir, "commit", "-m", "init")
		runGit(t, dir, "switch", "-c", "topic")

		var stdout, stderr bytes.Buffer
		if err := runWT([]string{"promote"}, dir, &stdout, &stderr); err == nil || !strings.Contains(err.Error(), "clean-bare") {
			t.Fatalf("expected clean-bare error, got %v", err)
		}
	})
}

func TestRunWT_PR(t *testing.T) {
	t.Run("checks out PR into a new flat worktree without touching default worktree", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/from-pr"}, "")

		var viewedRef, viewedRepo string
		var checkoutDir, checkoutRef, checkoutRepo, checkoutBranch string
		deps := wtPRDeps{
			viewPR: func(_ string, prRef, repo string, _ io.Writer) (ghPRInfo, error) {
				viewedRef = prRef
				viewedRepo = repo
				return ghPRInfo{
					Number:            123,
					HeadRefName:       "feat/from-pr",
					IsCrossRepository: false,
				}, nil
			},
			checkoutPR: func(workDir, prRef, repo, branch string, _ io.Writer) error {
				checkoutDir = workDir
				checkoutRef = prRef
				checkoutRepo = repo
				checkoutBranch = branch
				runGit(t, workDir, "switch", "--track", "-c", "feat/from-pr", "origin/feat/from-pr")
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := wtRunPRWithDeps([]string{"--repo", "NixOS/nixpkgs", "#123"}, defaultWT, deps, &stdout, &stderr); err != nil {
			t.Fatalf("wt pr failed: %v, stderr: %s", err, stderr.String())
		}

		wantDir := filepath.Join(repoDir, "feat-from-pr")
		if got := strings.TrimSpace(stdout.String()); got != wantDir {
			t.Fatalf("stdout = %q, want %q", got, wantDir)
		}
		if viewedRef != "123" || viewedRepo != "NixOS/nixpkgs" {
			t.Errorf("viewPR called with (%q, %q), want (123, NixOS/nixpkgs)", viewedRef, viewedRepo)
		}
		if checkoutDir != wantDir || checkoutRef != "123" || checkoutRepo != "NixOS/nixpkgs" || checkoutBranch != "" {
			t.Errorf("checkoutPR called with (%q, %q, %q, %q)", checkoutDir, checkoutRef, checkoutRepo, checkoutBranch)
		}
		if br := runGit(t, defaultWT, "symbolic-ref", "--short", "HEAD"); br != "main" {
			t.Errorf("default worktree branch = %q, want main", br)
		}
		if br := runGit(t, wantDir, "symbolic-ref", "--short", "HEAD"); br != "feat/from-pr" {
			t.Errorf("PR worktree branch = %q, want feat/from-pr", br)
		}
	})

	t.Run("avoids branch collision for cross-repo PR from default branch name", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "")

		var gotBranch string
		deps := wtPRDeps{
			viewPR: func(_ string, _ string, _ string, _ io.Writer) (ghPRInfo, error) {
				return ghPRInfo{
					Number:            456,
					HeadRefName:       "main",
					IsCrossRepository: true,
				}, nil
			},
			checkoutPR: func(workDir, _ string, _ string, branch string, _ io.Writer) error {
				gotBranch = branch
				runGit(t, workDir, "switch", "-c", branch)
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := wtRunPRWithDeps([]string{"456"}, defaultWT, deps, &stdout, &stderr); err != nil {
			t.Fatalf("wt pr cross-repo main failed: %v, stderr: %s", err, stderr.String())
		}
		wantDir := filepath.Join(repoDir, "pr-456")
		if got := strings.TrimSpace(stdout.String()); got != wantDir {
			t.Fatalf("stdout = %q, want %q", got, wantDir)
		}
		if gotBranch != "pr-456" {
			t.Errorf("checkoutPR branch = %q, want pr-456", gotBranch)
		}
	})

	t.Run("rolls back temporary worktree when gh pr checkout fails", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "")

		deps := wtPRDeps{
			viewPR: func(_ string, _ string, _ string, _ io.Writer) (ghPRInfo, error) {
				return ghPRInfo{
					Number:      789,
					HeadRefName: "feat/broken",
				}, nil
			},
			checkoutPR: func(_ string, _ string, _ string, _ string, _ io.Writer) error {
				return errors.New("simulated gh checkout failure")
			},
		}

		var stdout, stderr bytes.Buffer
		if err := wtRunPRWithDeps([]string{"789"}, defaultWT, deps, &stdout, &stderr); err == nil {
			t.Fatalf("expected error on gh checkout failure")
		}
		if _, err := os.Stat(filepath.Join(repoDir, "feat-broken")); !os.IsNotExist(err) {
			t.Errorf("expected rolled-back worktree directory not to exist, got err=%v", err)
		}
	})

	t.Run("refuses when PR branch is currently checked out in default worktree", func(t *testing.T) {
		isolateEnv(t)
		_, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/in-default"}, "")
		runGit(t, defaultWT, "switch", "--track", "-c", "feat/in-default", "origin/feat/in-default")

		deps := wtPRDeps{
			viewPR: func(_ string, _ string, _ string, _ io.Writer) (ghPRInfo, error) {
				return ghPRInfo{
					Number:      321,
					HeadRefName: "feat/in-default",
				}, nil
			},
		}

		var stdout, stderr bytes.Buffer
		err := wtRunPRWithDeps([]string{"321"}, defaultWT, deps, &stdout, &stderr)
		if err == nil || !strings.Contains(err.Error(), "wt promote") {
			t.Fatalf("expected error mentioning wt promote, got %v", err)
		}
	})

	t.Run("reuses existing dedicated worktree for the PR branch", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/existing"}, "")

		var stdout, stderr bytes.Buffer
		if err := runWT([]string{"add", "--branch", "feat/existing"}, defaultWT, &stdout, &stderr); err != nil {
			t.Fatalf("wt add failed: %v", err)
		}
		existingWT := filepath.Join(repoDir, "feat-existing")

		var checkoutDir string
		deps := wtPRDeps{
			viewPR: func(_ string, _ string, _ string, _ io.Writer) (ghPRInfo, error) {
				return ghPRInfo{
					Number:      555,
					HeadRefName: "feat/existing",
				}, nil
			},
			checkoutPR: func(workDir, _ string, _ string, _ string, _ io.Writer) error {
				checkoutDir = workDir
				return nil
			},
		}

		stdout.Reset()
		stderr.Reset()
		if err := wtRunPRWithDeps([]string{"555"}, defaultWT, deps, &stdout, &stderr); err != nil {
			t.Fatalf("wt pr reuse failed: %v, stderr: %s", err, stderr.String())
		}
		if got := strings.TrimSpace(stdout.String()); got != existingWT {
			t.Errorf("stdout = %q, want %q", got, existingWT)
		}
		if checkoutDir != existingWT {
			t.Errorf("checkoutDir = %q, want %q", checkoutDir, existingWT)
		}
	})

	t.Run("falls back to gh pr checkout in non-clean-bare repositories", func(t *testing.T) {
		isolateEnv(t)
		dir := t.TempDir()
		runGit(t, dir, "init", "-b", "main")
		runGit(t, dir, "config", "user.name", "Tester")
		runGit(t, dir, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(dir, "README.md"), "hi\n")
		runGit(t, dir, "add", ".")
		runGit(t, dir, "commit", "-m", "init")

		called := false
		deps := wtPRDeps{
			viewPR: func(_ string, _ string, _ string, _ io.Writer) (ghPRInfo, error) {
				t.Fatalf("viewPR should not be called in non-clean-bare repo")
				return ghPRInfo{}, nil
			},
			checkoutPR: func(workDir, prRef, repo, branch string, _ io.Writer) error {
				called = true
				if workDir != dir || prRef != "99" || repo != "owner/repo" || branch != "" {
					t.Errorf("unexpected fallback args: (%q, %q, %q, %q)", workDir, prRef, repo, branch)
				}
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := wtRunPRWithDeps([]string{"--repo", "owner/repo", "#99"}, dir, deps, &stdout, &stderr); err != nil {
			t.Fatalf("fallback wt pr failed: %v", err)
		}
		if !called {
			t.Errorf("expected checkoutPR fallback to be called")
		}
		if stdout.Len() != 0 {
			t.Errorf("expected empty stdout on fallback, got %q", stdout.String())
		}
	})
}

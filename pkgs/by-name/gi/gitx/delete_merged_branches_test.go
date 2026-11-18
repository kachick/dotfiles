package main

import (
	"bytes"
	"os"
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

func listBranches(t *testing.T, dir string) []string {
	t.Helper()
	out := runGit(t, dir, "for-each-ref", "--sort=refname", "--format=%(refname:short)", "refs/heads/")
	if out == "" {
		return nil
	}
	return strings.Split(out, "\n")
}

func TestRun_DeleteMergedBranches(t *testing.T) {
	t.Run("removes clean merged worktrees and branches while preserving dirty, current, unmerged, and protected ones", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		seed := filepath.Join(temp, "seed")
		runGit(t, temp, "init", "-b", "trunk", seed)
		runGit(t, seed, "config", "user.name", "Tester")
		runGit(t, seed, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(seed, "README.md"), "hello\n")
		runGit(t, seed, "add", ".")
		runGit(t, seed, "commit", "-m", "Initial commit")

		for _, br := range []string{"feat/merged-clean", "merged-dirty", "merged-current", "merged-no-wt", "develop"} {
			runGit(t, seed, "checkout", "-b", br)
			f := filepath.Join(seed, strings.ReplaceAll(br, "/", "-")+".txt")
			writeTestFile(t, f, br+"\n")
			runGit(t, seed, "add", ".")
			runGit(t, seed, "commit", "-m", "Commit "+br)
			runGit(t, seed, "checkout", "trunk")
			runGit(t, seed, "merge", "--no-ff", br, "-m", "Merge "+br)
		}

		repoDir := filepath.Join(temp, "repo")
		if err := os.MkdirAll(repoDir, 0o755); err != nil {
			t.Fatalf("mkdir repoDir: %v", err)
		}
		runGit(t, repoDir, "clone", "--bare", seed, filepath.Join(repoDir, ".git"))
		runGit(t, repoDir, "config", "set", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*")
		runGit(t, repoDir, "fetch", "--quiet", "origin")
		runGit(t, repoDir, "remote", "set-head", "origin", "--auto")

		trunkWT := filepath.Join(repoDir, "trunk")
		cleanWT := filepath.Join(repoDir, "feat-merged-clean")
		dirtyWT := filepath.Join(repoDir, "merged-dirty")
		currentWT := filepath.Join(repoDir, "merged-current")
		unmergedWT := filepath.Join(repoDir, "unmerged")

		runGit(t, repoDir, "worktree", "add", trunkWT, "trunk")
		runGit(t, repoDir, "worktree", "add", cleanWT, "feat/merged-clean")
		runGit(t, repoDir, "worktree", "add", dirtyWT, "merged-dirty")
		runGit(t, repoDir, "worktree", "add", currentWT, "merged-current")

		runGit(t, repoDir, "worktree", "add", "-b", "unmerged", unmergedWT, "trunk")
		runGit(t, unmergedWT, "config", "user.name", "Tester")
		runGit(t, unmergedWT, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(unmergedWT, "wip.txt"), "wip\n")
		runGit(t, unmergedWT, "add", "wip.txt")
		runGit(t, unmergedWT, "commit", "-m", "WIP on unmerged")

		writeTestFile(t, filepath.Join(dirtyWT, "notes.txt"), "unsaved\n")

		// Dry-run must not remove any worktrees or branches.
		var stdout, stderr bytes.Buffer
		if err := runDeleteMergedBranches([]string{"--dry-run"}, currentWT, &stdout, &stderr); err != nil {
			t.Fatalf("dry-run failed: %v, stderr: %s", err, stderr.String())
		}
		if _, err := os.Stat(cleanWT); err != nil {
			t.Errorf("dry-run should preserve %s: %v", cleanWT, err)
		}
		if !strings.Contains(stdout.String(), "[dry-run]") {
			t.Errorf("expected [dry-run] output, got: %s", stdout.String())
		}

		// Run from inside a subdirectory of merged-current: merged-current must be skipped,
		// while feat/merged-clean and merged-no-wt are removed.
		subDir := filepath.Join(currentWT, "nested")
		if err := os.MkdirAll(subDir, 0o755); err != nil {
			t.Fatalf("mkdir nested: %v", err)
		}
		stdout.Reset()
		stderr.Reset()
		if err := runDeleteMergedBranches(nil, subDir, &stdout, &stderr); err != nil {
			t.Fatalf("run failed from nested currentWT: %v, stderr: %s", err, stderr.String())
		}

		if _, err := os.Stat(cleanWT); !os.IsNotExist(err) {
			t.Errorf("expected clean merged worktree %s to be removed", cleanWT)
		}
		if _, err := os.Stat(dirtyWT); err != nil {
			t.Errorf("expected dirty merged worktree %s to be preserved: %v", dirtyWT, err)
		}
		if _, err := os.Stat(currentWT); err != nil {
			t.Errorf("expected current merged worktree %s to be preserved: %v", currentWT, err)
		}
		if _, err := os.Stat(unmergedWT); err != nil {
			t.Errorf("expected unmerged worktree %s to be preserved: %v", unmergedWT, err)
		}

		branches := listBranches(t, repoDir)
		for _, deleted := range []string{"feat/merged-clean", "merged-no-wt"} {
			if slices.Contains(branches, deleted) {
				t.Errorf("expected branch %q to be deleted; remaining: %v", deleted, branches)
			}
		}
		for _, kept := range []string{"trunk", "develop", "merged-dirty", "merged-current", "unmerged"} {
			if !slices.Contains(branches, kept) {
				t.Errorf("expected branch %q to be kept; remaining: %v", kept, branches)
			}
		}

		// Run again from trunkWT: now merged-current can be removed cleanly.
		stdout.Reset()
		stderr.Reset()
		if err := runDeleteMergedBranches(nil, trunkWT, &stdout, &stderr); err != nil {
			t.Fatalf("run failed from trunkWT: %v, stderr: %s", err, stderr.String())
		}
		if _, err := os.Stat(currentWT); !os.IsNotExist(err) {
			t.Errorf("expected merged-current worktree %s to be removed when run from trunkWT", currentWT)
		}
		branches = listBranches(t, repoDir)
		if slices.Contains(branches, "merged-current") {
			t.Errorf("expected merged-current branch to be deleted; remaining: %v", branches)
		}
	})

	t.Run("deletes merged branches from an unmerged worktree branched earlier than the merge", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		seed := filepath.Join(temp, "seed")
		runGit(t, temp, "init", "-b", "main", seed)
		runGit(t, seed, "config", "user.name", "Tester")
		runGit(t, seed, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(seed, "README.md"), "hello\n")
		runGit(t, seed, "add", ".")
		runGit(t, seed, "commit", "-m", "Initial commit")

		runGit(t, seed, "checkout", "-b", "older-unmerged")
		writeTestFile(t, filepath.Join(seed, "older.txt"), "older\n")
		runGit(t, seed, "add", ".")
		runGit(t, seed, "commit", "-m", "Commit older")

		runGit(t, seed, "checkout", "main")
		runGit(t, seed, "checkout", "-b", "feat-later")
		writeTestFile(t, filepath.Join(seed, "later.txt"), "later\n")
		runGit(t, seed, "add", ".")
		runGit(t, seed, "commit", "-m", "Commit later")
		runGit(t, seed, "checkout", "main")
		runGit(t, seed, "merge", "--no-ff", "feat-later", "-m", "Merge feat-later")

		repoDir := filepath.Join(temp, "repo")
		if err := os.MkdirAll(repoDir, 0o755); err != nil {
			t.Fatalf("mkdir repoDir: %v", err)
		}
		runGit(t, repoDir, "clone", "--bare", seed, filepath.Join(repoDir, ".git"))
		runGit(t, repoDir, "config", "set", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*")
		runGit(t, repoDir, "fetch", "--quiet", "origin")
		runGit(t, repoDir, "remote", "set-head", "origin", "--auto")

		mainWT := filepath.Join(repoDir, "main")
		olderWT := filepath.Join(repoDir, "older-unmerged")
		laterWT := filepath.Join(repoDir, "feat-later")
		runGit(t, repoDir, "worktree", "add", mainWT, "main")
		runGit(t, repoDir, "worktree", "add", olderWT, "older-unmerged")
		runGit(t, repoDir, "worktree", "add", laterWT, "feat-later")

		var stdout, stderr bytes.Buffer
		if err := runDeleteMergedBranches(nil, olderWT, &stdout, &stderr); err != nil {
			t.Fatalf("run failed from olderWT: %v, stderr: %s", err, stderr.String())
		}
		if _, err := os.Stat(laterWT); !os.IsNotExist(err) {
			t.Errorf("expected feat-later worktree to be removed")
		}
		branches := listBranches(t, repoDir)
		if slices.Contains(branches, "feat-later") {
			t.Errorf("expected feat-later branch to be deleted; remaining: %v", branches)
		}
	})

	t.Run("works in legacy non-bare repository with linked worktrees", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		repoDir := filepath.Join(temp, "legacy")
		runGit(t, temp, "init", "-b", "main", repoDir)
		runGit(t, repoDir, "config", "user.name", "Tester")
		runGit(t, repoDir, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(repoDir, "README.md"), "hello\n")
		runGit(t, repoDir, "add", ".")
		runGit(t, repoDir, "commit", "-m", "Initial commit")

		for _, br := range []string{"merged-linked", "merged-dirty", "merged-plain"} {
			runGit(t, repoDir, "checkout", "-b", br)
			writeTestFile(t, filepath.Join(repoDir, br+".txt"), br+"\n")
			runGit(t, repoDir, "add", ".")
			runGit(t, repoDir, "commit", "-m", "Commit "+br)
			runGit(t, repoDir, "checkout", "main")
			runGit(t, repoDir, "merge", "--no-ff", br, "-m", "Merge "+br)
		}

		linkedClean := filepath.Join(temp, "legacy-linked-clean")
		linkedDirty := filepath.Join(temp, "legacy-linked-dirty")
		runGit(t, repoDir, "worktree", "add", linkedClean, "merged-linked")
		runGit(t, repoDir, "worktree", "add", linkedDirty, "merged-dirty")
		writeTestFile(t, filepath.Join(linkedDirty, "dirty.txt"), "dirty\n")

		var stdout, stderr bytes.Buffer
		if err := runDeleteMergedBranches(nil, repoDir, &stdout, &stderr); err != nil {
			t.Fatalf("run failed in legacy repo: %v, stderr: %s", err, stderr.String())
		}

		if _, err := os.Stat(linkedClean); !os.IsNotExist(err) {
			t.Errorf("expected clean linked worktree %s to be removed", linkedClean)
		}
		if _, err := os.Stat(linkedDirty); err != nil {
			t.Errorf("expected dirty linked worktree %s to be preserved: %v", linkedDirty, err)
		}

		branches := listBranches(t, repoDir)
		for _, deleted := range []string{"merged-linked", "merged-plain"} {
			if slices.Contains(branches, deleted) {
				t.Errorf("expected %q to be deleted; remaining: %v", deleted, branches)
			}
		}
		for _, kept := range []string{"main", "merged-dirty"} {
			if !slices.Contains(branches, kept) {
				t.Errorf("expected %q to be kept; remaining: %v", kept, branches)
			}
		}
	})

	t.Run("prefers standard default branch over feature HEAD in legacy non-bare repo without origin HEAD", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		repoDir := filepath.Join(temp, "legacy")
		runGit(t, temp, "init", "-b", "main", repoDir)
		runGit(t, repoDir, "config", "user.name", "Tester")
		runGit(t, repoDir, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(repoDir, "README.md"), "hello\n")
		runGit(t, repoDir, "add", ".")
		runGit(t, repoDir, "commit", "-m", "Initial commit")

		runGit(t, repoDir, "checkout", "-b", "merged-feat")
		writeTestFile(t, filepath.Join(repoDir, "merged.txt"), "m\n")
		runGit(t, repoDir, "add", ".")
		runGit(t, repoDir, "commit", "-m", "Merged feat")
		runGit(t, repoDir, "checkout", "main")
		runGit(t, repoDir, "merge", "--no-ff", "merged-feat", "-m", "Merge feat")

		// Check out an unmerged branch branched earlier from initial commit so HEAD != main.
		runGit(t, repoDir, "checkout", "-b", "unmerged-feat", "HEAD~1")
		writeTestFile(t, filepath.Join(repoDir, "wip.txt"), "wip\n")
		runGit(t, repoDir, "add", ".")
		runGit(t, repoDir, "commit", "-m", "WIP")

		mainWT := filepath.Join(temp, "legacy-main")
		runGit(t, repoDir, "worktree", "add", mainWT, "main")

		var stdout, stderr bytes.Buffer
		if err := runDeleteMergedBranches(nil, repoDir, &stdout, &stderr); err != nil {
			t.Fatalf("run failed: %v, stderr: %s", err, stderr.String())
		}

		branches := listBranches(t, repoDir)
		if slices.Contains(branches, "merged-feat") {
			t.Errorf("expected merged-feat to be deleted even when HEAD is unmerged-feat; remaining: %v", branches)
		}
		for _, kept := range []string{"main", "unmerged-feat"} {
			if !slices.Contains(branches, kept) {
				t.Errorf("expected %q to be kept; remaining: %v", kept, branches)
			}
		}
	})

	t.Run("deletes merged branch from clean-bare root with inherited GIT_DIR=.git", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		seed := filepath.Join(temp, "seed")
		runGit(t, temp, "init", "-b", "main", seed)
		runGit(t, seed, "config", "user.name", "Tester")
		runGit(t, seed, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(seed, "README.md"), "hello\n")
		runGit(t, seed, "add", ".")
		runGit(t, seed, "commit", "-m", "Initial commit")
		runGit(t, seed, "checkout", "-b", "merged-bare")
		writeTestFile(t, filepath.Join(seed, "b.txt"), "b\n")
		runGit(t, seed, "add", ".")
		runGit(t, seed, "commit", "-m", "Commit b")
		runGit(t, seed, "checkout", "main")
		runGit(t, seed, "merge", "--no-ff", "merged-bare", "-m", "Merge b")

		repoDir := filepath.Join(temp, "repo")
		if err := os.MkdirAll(repoDir, 0o755); err != nil {
			t.Fatalf("mkdir repoDir: %v", err)
		}
		runGit(t, repoDir, "clone", "--bare", seed, filepath.Join(repoDir, ".git"))

		// Simulate invocation from `git all` (`!gitx refresh && gitx delete-merged-branches`) at bare root.
		t.Setenv("GIT_DIR", ".git")
		var stdout, stderr bytes.Buffer
		if err := runDeleteMergedBranches(nil, repoDir, &stdout, &stderr); err != nil {
			t.Fatalf("run failed from bare root with GIT_DIR=.git: %v, stderr: %s", err, stderr.String())
		}

		branches := listBranches(t, repoDir)
		if slices.Contains(branches, "merged-bare") {
			t.Errorf("expected merged-bare to be deleted; remaining: %v", branches)
		}
		if !slices.Contains(branches, "main") {
			t.Errorf("expected main to be kept; remaining: %v", branches)
		}
	})
}

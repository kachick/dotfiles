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

		// Simulate invocation from `git all` (`!git-x refresh && git-x delete-merged-branches`) at bare root.
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

	t.Run("deletes squash-merged PR branches and clean worktrees in clean-bare layout when --pr is enabled", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		seed := filepath.Join(temp, "seed")
		runGit(t, temp, "init", "-b", "main", seed)
		runGit(t, seed, "config", "user.name", "Tester")
		runGit(t, seed, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(seed, "README.md"), "hello\n")
		runGit(t, seed, "add", ".")
		runGit(t, seed, "commit", "-m", "Initial commit")

		makeBranch := func(name string) {
			runGit(t, seed, "checkout", "-b", name, "main")
			writeTestFile(t, filepath.Join(seed, strings.ReplaceAll(name, "/", "-")+".txt"), name+"\n")
			runGit(t, seed, "add", ".")
			runGit(t, seed, "commit", "-m", "Commit "+name)
		}

		for _, br := range []string{
			"feat/squash-clean",
			"feat/squash-dirty",
			"feat/squash-current",
			"feat/squash-reused",
			"feat/squash-open",
			"feat/closed-only",
			"backup-main-8eab2526-e8b0-4a8f-95ce-63175cb16d04",
			"develop",
		} {
			makeBranch(br)
		}
		runGit(t, seed, "checkout", "main")

		repoDir := filepath.Join(temp, "repo")
		if err := os.MkdirAll(repoDir, 0o755); err != nil {
			t.Fatalf("mkdir repoDir: %v", err)
		}
		runGit(t, repoDir, "clone", "--bare", seed, filepath.Join(repoDir, ".git"))
		runGit(t, repoDir, "config", "set", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*")
		runGit(t, repoDir, "fetch", "--quiet", "origin")
		runGit(t, repoDir, "remote", "set-head", "origin", "--auto")
		runGit(t, repoDir, "remote", "set-url", "origin", "https://github.com/example/clean-bare.git")

		mainWT := filepath.Join(repoDir, "main")
		cleanWT := filepath.Join(repoDir, "feat-squash-clean")
		dirtyWT := filepath.Join(repoDir, "feat-squash-dirty")
		currentWT := filepath.Join(repoDir, "feat-squash-current")
		runGit(t, repoDir, "worktree", "add", mainWT, "main")
		runGit(t, repoDir, "worktree", "add", cleanWT, "feat/squash-clean")
		runGit(t, repoDir, "worktree", "add", dirtyWT, "feat/squash-dirty")
		runGit(t, repoDir, "worktree", "add", currentWT, "feat/squash-current")
		writeTestFile(t, filepath.Join(dirtyWT, "dirty.txt"), "unsaved\n")

		oidOf := func(br string) string {
			return runGit(t, repoDir, "rev-parse", br)
		}

		var lookedUp []string
		fakeLookup := func(workDir, repo string, branches []string) (map[string][]pullRequestInfo, error) {
			if repo != "example/clean-bare" {
				t.Fatalf("unexpected repo: got %q, want %q", repo, "example/clean-bare")
			}
			if workDir != mainWT {
				t.Fatalf("unexpected gh workDir: got %q, want %q", workDir, mainWT)
			}
			lookedUp = append(lookedUp, branches...)
			res := make(map[string][]pullRequestInfo, len(branches))
			for _, branch := range branches {
				switch branch {
				case "feat/squash-clean", "feat/squash-dirty":
					res[branch] = []pullRequestInfo{{State: "MERGED", HeadRefName: branch, HeadRefOid: oidOf(branch)}}
				case "feat/squash-reused":
					res[branch] = []pullRequestInfo{{State: "MERGED", HeadRefName: branch, HeadRefOid: "0000000000000000000000000000000000000000"}}
				case "feat/squash-open":
					res[branch] = []pullRequestInfo{
						{State: "MERGED", HeadRefName: branch, HeadRefOid: oidOf(branch)},
						{State: "OPEN", HeadRefName: branch, HeadRefOid: oidOf(branch)},
					}
				case "feat/closed-only":
					res[branch] = []pullRequestInfo{{State: "CLOSED", HeadRefName: branch, HeadRefOid: oidOf(branch)}}
				}
			}
			return res, nil
		}

		var stdout, stderr bytes.Buffer
		if err := runDeleteMergedBranchesWithLookup([]string{"--dry-run", "--pr"}, currentWT, fakeLookup, &stdout, &stderr); err != nil {
			t.Fatalf("dry-run --pr failed: %v, stderr: %s", err, stderr.String())
		}
		if _, err := os.Stat(cleanWT); err != nil {
			t.Errorf("dry-run should preserve %s: %v", cleanWT, err)
		}
		if !strings.Contains(stdout.String(), "[dry-run] git branch -D feat/squash-clean") {
			t.Errorf("expected dry-run -D output, got: %s", stdout.String())
		}

		lookedUp = nil
		stdout.Reset()
		stderr.Reset()
		if err := runDeleteMergedBranchesWithLookup([]string{"--pr"}, currentWT, fakeLookup, &stdout, &stderr); err != nil {
			t.Fatalf("--pr run failed: %v, stderr: %s", err, stderr.String())
		}

		if slices.Contains(lookedUp, "develop") {
			t.Errorf("protected branch develop should not trigger PR lookup: %v", lookedUp)
		}
		if slices.Contains(lookedUp, "backup-main-8eab2526-e8b0-4a8f-95ce-63175cb16d04") {
			t.Errorf("reset-branch backup branch should not trigger PR lookup: %v", lookedUp)
		}
		if slices.Contains(lookedUp, "feat/squash-current") {
			t.Errorf("current worktree branch should not trigger PR lookup: %v", lookedUp)
		}
		if !strings.Contains(stderr.String(), "Skipping branch feat/squash-current (currently inside worktree") {
			t.Errorf("expected accurate skip message for current unmerged worktree, got: %s", stderr.String())
		}
		if _, err := os.Stat(cleanWT); !os.IsNotExist(err) {
			t.Errorf("expected clean squash-merged worktree %s to be removed", cleanWT)
		}
		if _, err := os.Stat(dirtyWT); err != nil {
			t.Errorf("expected dirty squash-merged worktree %s to be preserved: %v", dirtyWT, err)
		}
		if _, err := os.Stat(currentWT); err != nil {
			t.Errorf("expected current squash-merged worktree %s to be preserved: %v", currentWT, err)
		}

		branches := listBranches(t, repoDir)
		if slices.Contains(branches, "feat/squash-clean") {
			t.Errorf("expected feat/squash-clean to be deleted; remaining: %v", branches)
		}
		for _, kept := range []string{
			"main",
			"develop",
			"feat/squash-dirty",
			"feat/squash-current",
			"feat/squash-reused",
			"feat/squash-open",
			"feat/closed-only",
			"backup-main-8eab2526-e8b0-4a8f-95ce-63175cb16d04",
		} {
			if !slices.Contains(branches, kept) {
				t.Errorf("expected %q to be kept; remaining: %v", kept, branches)
			}
		}
	})

	t.Run("deletes squash-merged PR branches in classic non-bare layout preferring upstream remote", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		repoDir := filepath.Join(temp, "classic")
		runGit(t, temp, "init", "-b", "main", repoDir)
		runGit(t, repoDir, "config", "user.name", "Tester")
		runGit(t, repoDir, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(repoDir, "README.md"), "hello\n")
		runGit(t, repoDir, "add", ".")
		runGit(t, repoDir, "commit", "-m", "Initial commit")
		runGit(t, repoDir, "remote", "add", "origin", "git@github.com:forkuser/repo.git")
		runGit(t, repoDir, "remote", "add", "upstream", "https://github.com/parentorg/repo.git")

		for _, br := range []string{"squash-linked", "squash-plain", "unmerged-wip"} {
			runGit(t, repoDir, "checkout", "-b", br, "main")
			writeTestFile(t, filepath.Join(repoDir, br+".txt"), br+"\n")
			runGit(t, repoDir, "add", ".")
			runGit(t, repoDir, "commit", "-m", "Commit "+br)
		}
		runGit(t, repoDir, "checkout", "main")

		linkedWT := filepath.Join(temp, "classic-linked")
		runGit(t, repoDir, "worktree", "add", linkedWT, "squash-linked")

		oidOf := func(br string) string {
			return runGit(t, repoDir, "rev-parse", br)
		}

		fakeLookup := func(_, repo string, branches []string) (map[string][]pullRequestInfo, error) {
			if repo != "parentorg/repo" {
				t.Fatalf("expected upstream repo parentorg/repo, got %q", repo)
			}
			res := make(map[string][]pullRequestInfo, len(branches))
			for _, branch := range branches {
				switch branch {
				case "squash-linked", "squash-plain":
					res[branch] = []pullRequestInfo{{State: "MERGED", HeadRefName: branch, HeadRefOid: oidOf(branch)}}
				}
			}
			return res, nil
		}

		var stdout, stderr bytes.Buffer
		if err := runDeleteMergedBranchesWithLookup([]string{"--pr"}, repoDir, fakeLookup, &stdout, &stderr); err != nil {
			t.Fatalf("--pr failed in classic repo: %v, stderr: %s", err, stderr.String())
		}
		if _, err := os.Stat(linkedWT); !os.IsNotExist(err) {
			t.Errorf("expected linked worktree %s to be removed", linkedWT)
		}
		branches := listBranches(t, repoDir)
		for _, deleted := range []string{"squash-linked", "squash-plain"} {
			if slices.Contains(branches, deleted) {
				t.Errorf("expected %q to be deleted; remaining: %v", deleted, branches)
			}
		}
		for _, kept := range []string{"main", "unmerged-wip"} {
			if !slices.Contains(branches, kept) {
				t.Errorf("expected %q to be kept; remaining: %v", kept, branches)
			}
		}
	})

	t.Run("skips clean-bare default worktree with warning even when it checks out a merged or squash-merged branch", func(t *testing.T) {
		isolateEnv(t)
		temp := t.TempDir()
		seed := filepath.Join(temp, "seed")
		runGit(t, temp, "init", "-b", "main", seed)
		runGit(t, seed, "config", "user.name", "Tester")
		runGit(t, seed, "config", "user.email", "tester@example.com")
		writeTestFile(t, filepath.Join(seed, "README.md"), "hello\n")
		runGit(t, seed, "add", ".")
		runGit(t, seed, "commit", "-m", "Initial commit")

		runGit(t, seed, "checkout", "-b", "feat/misplaced-merged")
		writeTestFile(t, filepath.Join(seed, "m.txt"), "m\n")
		runGit(t, seed, "add", ".")
		runGit(t, seed, "commit", "-m", "Merged feature")
		runGit(t, seed, "checkout", "main")
		runGit(t, seed, "merge", "--no-ff", "feat/misplaced-merged", "-m", "Merge feat/misplaced-merged")

		runGit(t, seed, "checkout", "-b", "feat/misplaced-squash", "main")
		writeTestFile(t, filepath.Join(seed, "s.txt"), "s\n")
		runGit(t, seed, "add", ".")
		runGit(t, seed, "commit", "-m", "Squash feature")
		runGit(t, seed, "checkout", "main")

		repoDir := filepath.Join(temp, "repo")
		if err := os.MkdirAll(repoDir, 0o755); err != nil {
			t.Fatalf("mkdir repoDir: %v", err)
		}
		runGit(t, repoDir, "clone", "--bare", seed, filepath.Join(repoDir, ".git"))
		runGit(t, repoDir, "config", "set", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*")
		runGit(t, repoDir, "fetch", "--quiet", "origin")
		runGit(t, repoDir, "remote", "set-head", "origin", "--auto")
		runGit(t, repoDir, "remote", "set-url", "origin", "https://github.com/example/clean-bare.git")

		mainWT := filepath.Join(repoDir, "main")
		otherWT := filepath.Join(repoDir, "other")
		runGit(t, repoDir, "worktree", "add", mainWT, "feat/misplaced-merged")
		runGit(t, repoDir, "worktree", "add", "-b", "other", otherWT, "main")

		var stdout, stderr bytes.Buffer
		if err := runDeleteMergedBranches(nil, otherWT, &stdout, &stderr); err != nil {
			t.Fatalf("runDeleteMergedBranches failed: %v, stderr: %s", err, stderr.String())
		}
		if _, err := os.Stat(mainWT); err != nil {
			t.Errorf("expected default worktree %s to be preserved: %v", mainWT, err)
		}
		if !strings.Contains(stderr.String(), "default worktree") {
			t.Errorf("expected warning about default worktree in stderr, got: %s", stderr.String())
		}
		if !slices.Contains(listBranches(t, repoDir), "feat/misplaced-merged") {
			t.Errorf("expected branch checked out in default worktree to be preserved")
		}

		// Also protect when default worktree checks out a squash-merged PR branch under --pr.
		runGit(t, mainWT, "switch", "feat/misplaced-squash")
		squashOid := runGit(t, repoDir, "rev-parse", "feat/misplaced-squash")
		prLookupCalled := false
		fakeLookup := func(_, _ string, branches []string) (map[string][]pullRequestInfo, error) {
			prLookupCalled = true
			res := make(map[string][]pullRequestInfo, len(branches))
			for _, b := range branches {
				if b == "feat/misplaced-squash" {
					res[b] = []pullRequestInfo{{State: "MERGED", HeadRefName: b, HeadRefOid: squashOid}}
				}
			}
			return res, nil
		}

		stdout.Reset()
		stderr.Reset()
		if err := runDeleteMergedBranchesWithLookup([]string{"--pr"}, otherWT, fakeLookup, &stdout, &stderr); err != nil {
			t.Fatalf("runDeleteMergedBranches --pr failed: %v, stderr: %s", err, stderr.String())
		}
		if _, err := os.Stat(mainWT); err != nil {
			t.Errorf("expected default worktree %s to be preserved under --pr: %v", mainWT, err)
		}
		if prLookupCalled {
			t.Errorf("expected default worktree branch not to trigger PR lookup")
		}
		if !strings.Contains(stderr.String(), "default worktree") {
			t.Errorf("expected warning about default worktree under --pr in stderr, got: %s", stderr.String())
		}
		if !slices.Contains(listBranches(t, repoDir), "feat/misplaced-squash") {
			t.Errorf("expected squash-merged branch in default worktree to be preserved")
		}
	})
}

func TestParseGitHubRepoURL(t *testing.T) {
	cases := []struct {
		raw  string
		want string
		ok   bool
	}{
		{raw: "https://github.com/kachick/dotfiles.git", want: "kachick/dotfiles", ok: true},
		{raw: "https://github.com/kachick/dotfiles/", want: "kachick/dotfiles", ok: true},
		{raw: "git@github.com:kachick/dotfiles.git", want: "kachick/dotfiles", ok: true},
		{raw: "ssh://git@github.com/kachick/dotfiles.git", want: "kachick/dotfiles", ok: true},
		{raw: "https://gitlab.com/kachick/dotfiles.git", want: "", ok: false},
		{raw: "/tmp/local-seed", want: "", ok: false},
		{raw: "", want: "", ok: false},
	}

	for _, tc := range cases {
		got, ok := parseGitHubRepoURL(tc.raw)
		if got != tc.want || ok != tc.ok {
			t.Errorf("parseGitHubRepoURL(%q) = (%q, %v), want (%q, %v)", tc.raw, got, ok, tc.want, tc.ok)
		}
	}
}

func TestLookupMergedBranchPRsWithFakeGH(t *testing.T) {
	isolateEnv(t)
	logPath := installFakeTool(t, "gh", `
if [ "$FAKE_GH_EXIT" = "1" ]; then
  echo "auth required" >&2
  exit 1
fi
if [ "$FAKE_GH_GQL_ERR" = "1" ]; then
  printf '{"data":{"repository":null},"errors":[{"message":"Could not resolve to a Repository"}]}\n'
  exit 0
fi
printf '{"data":{"repository":{"open0":{"totalCount":0},"merged0":{"nodes":[{"headRefOid":"abc123"}]},"open1":{"totalCount":1},"merged1":{"nodes":[{"headRefOid":"def456"}]}}}}\n'
`)

	prsByBranch, err := lookupMergedBranchPRs(t.TempDir(), "kachick/dotfiles", []string{"feat/demo", "feat/open"})
	if err != nil {
		t.Fatalf("lookupMergedBranchPRs failed: %v", err)
	}
	if len(prsByBranch["feat/demo"]) != 1 || prsByBranch["feat/demo"][0].HeadRefOid != "abc123" || prsByBranch["feat/demo"][0].State != "MERGED" {
		t.Fatalf("unexpected PRs for feat/demo: %+v", prsByBranch["feat/demo"])
	}
	if !shouldDeleteFromPRs("feat/demo", "abc123", prsByBranch["feat/demo"]) {
		t.Error("expected feat/demo to be deletable")
	}
	if shouldDeleteFromPRs("feat/open", "def456", prsByBranch["feat/open"]) {
		t.Error("expected feat/open with openCount=1 not to be deletable")
	}

	logged := readTestFile(t, logPath)
	for _, wantSubstr := range []string{"api graphql", "owner=kachick", "name=dotfiles", "b0=feat/demo", "b1=feat/open"} {
		if !strings.Contains(logged, wantSubstr) {
			t.Errorf("gh args %q missing %q", logged, wantSubstr)
		}
	}

	t.Setenv("FAKE_GH_GQL_ERR", "1")
	if _, err := lookupMergedBranchPRs(t.TempDir(), "kachick/dotfiles", []string{"feat/demo"}); err == nil {
		t.Fatal("expected error when GraphQL returns errors, got nil")
	}

	t.Setenv("FAKE_GH_GQL_ERR", "")
	t.Setenv("FAKE_GH_EXIT", "1")
	if _, err := lookupMergedBranchPRs(t.TempDir(), "kachick/dotfiles", []string{"feat/demo"}); err == nil {
		t.Fatal("expected error when gh fails, got nil")
	}
}

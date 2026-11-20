package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

func createRepoSeedRepo(t *testing.T, defaultBranch string) string {
	t.Helper()
	temp := t.TempDir()
	seed := filepath.Join(temp, "seed")
	runGit(t, temp, "init", "-b", defaultBranch, seed)
	runGit(t, seed, "config", "user.name", "Tester")
	runGit(t, seed, "config", "user.email", "tester@example.com")
	writeTestFile(t, filepath.Join(seed, "README.md"), "hello\n")
	runGit(t, seed, "add", ".")
	runGit(t, seed, "commit", "-m", "Initial commit")
	return seed
}

func createRepoCleanBareRepo(t *testing.T, repoRoot, relRepo, defaultBranch string, extraWorktrees ...string) string {
	t.Helper()
	seed := createRepoSeedRepo(t, defaultBranch)
	repoDir := filepath.Join(repoRoot, filepath.FromSlash(relRepo))
	if err := os.MkdirAll(repoDir, 0o755); err != nil {
		t.Fatalf("mkdir repoDir: %v", err)
	}
	runGit(t, repoDir, "clone", "--bare", seed, filepath.Join(repoDir, ".git"))
	runGit(t, repoDir, "worktree", "add", filepath.Join(repoDir, defaultBranch), defaultBranch)
	for _, wt := range extraWorktrees {
		runGit(t, repoDir, "worktree", "add", "-b", wt, filepath.Join(repoDir, wt), defaultBranch)
	}
	return repoDir
}

func createRepoLegacyRepo(t *testing.T, repoRoot, relRepo, branch string) string {
	t.Helper()
	seed := createRepoSeedRepo(t, branch)
	repoDir := filepath.Join(repoRoot, filepath.FromSlash(relRepo))
	if err := os.MkdirAll(filepath.Dir(repoDir), 0o755); err != nil {
		t.Fatalf("mkdir parent: %v", err)
	}
	runGit(t, filepath.Dir(repoDir), "clone", seed, repoDir)
	return repoDir
}

func TestCollectAndRepoFzfRanking(t *testing.T) {
	repoRoot := t.TempDir()
	t.Setenv("GITX_ROOT", repoRoot)

	otherRepo := createRepoCleanBareRepo(t, repoRoot, "github.com/alpha/other-repo", "main", "feat-dotfiles")
	dotfilesRepo := createRepoCleanBareRepo(t, repoRoot, "github.com/kachick/dotfiles", "trunk", "feat-1")
	legacyRepo := createRepoLegacyRepo(t, repoRoot, "github.com/legacy/tool", "main")

	staleWT := filepath.Join(otherRepo, "stale-wt")
	runGit(t, otherRepo, "worktree", "add", "-b", "stale-wt", staleWT, "main")
	if err := os.RemoveAll(staleWT); err != nil {
		t.Fatalf("remove stale worktree dir: %v", err)
	}

	var listOut, stderr bytes.Buffer
	if err := runRepoFzf([]string{"--list"}, &listOut, &stderr); err != nil {
		t.Fatalf("repo-fzf --list failed: %v, stderr: %s", err, stderr.String())
	}

	lines := strings.Split(strings.TrimSpace(listOut.String()), "\n")
	wantLines := []string{
		"github.com/alpha/other-repo\tmain\t" + filepath.Join(otherRepo, "main"),
		"github.com/alpha/other-repo\tfeat-dotfiles\t" + filepath.Join(otherRepo, "feat-dotfiles"),
		"github.com/kachick/dotfiles\ttrunk\t" + filepath.Join(dotfilesRepo, "trunk"),
		"github.com/kachick/dotfiles\tfeat-1\t" + filepath.Join(dotfilesRepo, "feat-1"),
		"github.com/legacy/tool\t.\t" + legacyRepo,
	}

	for _, want := range wantLines {
		if !slices.Contains(lines, want) {
			t.Errorf("missing expected line %q in:\n%s", want, listOut.String())
		}
	}
	if strings.Contains(listOut.String(), "stale-wt") {
		t.Errorf("stale worktree should not appear in output:\n%s", listOut.String())
	}

	trunkIdx := slices.Index(lines, "github.com/kachick/dotfiles\ttrunk\t"+filepath.Join(dotfilesRepo, "trunk"))
	featIdx := slices.Index(lines, "github.com/kachick/dotfiles\tfeat-1\t"+filepath.Join(dotfilesRepo, "feat-1"))
	if trunkIdx < 0 || featIdx < 0 || trunkIdx >= featIdx {
		t.Errorf("expected trunk (idx=%d) before feat-1 (idx=%d)", trunkIdx, featIdx)
	}

	filterArgs := append([]string{"--filter=dotfiles"}, repoFzfFilterArgs("")...)
	cmd := exec.Command("fzf", filterArgs...)
	cmd.Stdin = strings.NewReader(listOut.String())
	out, err := cmd.Output()
	if err != nil {
		t.Fatalf("fzf --filter failed: %v", err)
	}
	ranked := strings.Split(strings.TrimSpace(string(out)), "\n")
	if len(ranked) < 3 {
		t.Fatalf("expected at least 3 matches for 'dotfiles', got %v", ranked)
	}

	wantTop := filepath.Join(dotfilesRepo, "trunk")
	wantBranchMatch := filepath.Join(otherRepo, "feat-dotfiles")
	if ranked[0] != wantTop {
		t.Errorf("top match = %q, want %q; full ranking: %v", ranked[0], wantTop, ranked)
	}
	if ranked[len(ranked)-1] != wantBranchMatch {
		t.Errorf("expected branch match %q to rank below repo matches; full ranking: %v", wantBranchMatch, ranked)
	}
}

func TestResolveRepoRoots(t *testing.T) {
	t.Run("prefers GITX_ROOT env and expands tilde", func(t *testing.T) {
		isolateEnv(t)
		home := os.Getenv("HOME")
		extra := t.TempDir()
		t.Setenv("GITX_ROOT", "~/primary"+string(filepath.ListSeparator)+extra)

		got, err := resolveRepoRoots()
		if err != nil {
			t.Fatalf("resolveRepoRoots failed: %v", err)
		}
		want := []string{filepath.Join(home, "primary"), filepath.Clean(extra)}
		if !slices.Equal(got, want) {
			t.Errorf("roots = %v, want %v", got, want)
		}
	})

	t.Run("reads git config gitx.root when GITX_ROOT is unset", func(t *testing.T) {
		isolateEnv(t)
		t.Setenv("GITX_ROOT", "")
		home := os.Getenv("HOME")
		second := t.TempDir()
		cfgPath := filepath.Join(t.TempDir(), "gitconfig")
		writeTestFile(t, cfgPath, fmt.Sprintf("[gitx]\n\troot = ~/cfg-repos\n\troot = %s\n", second))
		t.Setenv("GIT_CONFIG_GLOBAL", cfgPath)

		got, err := resolveRepoRoots()
		if err != nil {
			t.Fatalf("resolveRepoRoots failed: %v", err)
		}
		want := []string{filepath.Join(home, "cfg-repos"), filepath.Clean(second)}
		if !slices.Equal(got, want) {
			t.Errorf("roots = %v, want %v", got, want)
		}
	})

	t.Run("falls back to ~/repos when unconfigured", func(t *testing.T) {
		isolateEnv(t)
		t.Setenv("GITX_ROOT", "")
		home := os.Getenv("HOME")

		got, err := resolveRepoRoots()
		if err != nil {
			t.Fatalf("resolveRepoRoots failed: %v", err)
		}
		want := []string{filepath.Join(home, "repos")}
		if !slices.Equal(got, want) {
			t.Errorf("roots = %v, want %v", got, want)
		}
	})
}

func TestListReposInRoots(t *testing.T) {
	root1 := t.TempDir()
	root2 := t.TempDir()
	missingRoot := filepath.Join(t.TempDir(), "missing")

	repoA := createRepoCleanBareRepo(t, root1, "github.com/kachick/dotfiles", "trunk", "feat-1")
	repoB := createRepoLegacyRepo(t, root2, "gitlab.com/group/sub/nested", "main")

	// Hidden directories at depth 1 and depth 2 must be skipped.
	writeTestFile(t, filepath.Join(root1, ".hidden", "owner", "repo", ".git", "HEAD"), "ref: refs/heads/main\n")
	writeTestFile(t, filepath.Join(root1, "github.com", ".hidden", "repo", ".git", "HEAD"), "ref: refs/heads/main\n")

	got, err := listReposInRoots([]string{root1, missingRoot, root2, root1})
	if err != nil {
		t.Fatalf("listReposInRoots failed: %v", err)
	}

	want := []string{repoA, repoB}
	slices.Sort(want)
	if !slices.Equal(got, want) {
		t.Errorf("repos = %v, want %v", got, want)
	}
}

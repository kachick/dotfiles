package main

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

func createGhqSeedRepo(t *testing.T, defaultBranch string) string {
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

func createGhqCleanBareRepo(t *testing.T, ghqRoot, relRepo, defaultBranch string, extraWorktrees ...string) string {
	t.Helper()
	seed := createGhqSeedRepo(t, defaultBranch)
	repoDir := filepath.Join(ghqRoot, filepath.FromSlash(relRepo))
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

func createGhqLegacyRepo(t *testing.T, ghqRoot, relRepo, branch string) string {
	t.Helper()
	seed := createGhqSeedRepo(t, branch)
	repoDir := filepath.Join(ghqRoot, filepath.FromSlash(relRepo))
	if err := os.MkdirAll(filepath.Dir(repoDir), 0o755); err != nil {
		t.Fatalf("mkdir parent: %v", err)
	}
	runGit(t, filepath.Dir(repoDir), "clone", seed, repoDir)
	return repoDir
}

func TestCollectAndGhqFzfRanking(t *testing.T) {
	ghqRoot := t.TempDir()
	t.Setenv("GHQ_ROOT", ghqRoot)

	otherRepo := createGhqCleanBareRepo(t, ghqRoot, "github.com/alpha/other-repo", "main", "feat-dotfiles")
	dotfilesRepo := createGhqCleanBareRepo(t, ghqRoot, "github.com/kachick/dotfiles", "trunk", "feat-1")
	legacyRepo := createGhqLegacyRepo(t, ghqRoot, "github.com/legacy/tool", "main")

	staleWT := filepath.Join(otherRepo, "stale-wt")
	runGit(t, otherRepo, "worktree", "add", "-b", "stale-wt", staleWT, "main")
	if err := os.RemoveAll(staleWT); err != nil {
		t.Fatalf("remove stale worktree dir: %v", err)
	}

	var listOut, stderr bytes.Buffer
	if err := runGhqFzf([]string{"--list"}, &listOut, &stderr); err != nil {
		t.Fatalf("ghq-fzf --list failed: %v, stderr: %s", err, stderr.String())
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

	filterArgs := append([]string{"--filter=dotfiles"}, ghqFzfFilterArgs("")...)
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

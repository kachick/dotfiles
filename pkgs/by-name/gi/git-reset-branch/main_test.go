package main

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func runGitCmd(t *testing.T, dir string, args ...string) string {
	t.Helper()
	cmd := exec.Command("git", args...)
	cmd.Dir = dir
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("git %s failed: %v: %s", strings.Join(args, " "), err, string(out))
	}
	return strings.TrimSpace(string(out))
}

// setupSandbox creates an isolated test environment without running "git push".
//
// Why not git push:
// Even in sandboxed local tests, avoid running "git push" commands entirely.
// We seed commits into a local repository first and create the bare remote via "git clone --bare",
// which eliminates any accidental risk or fear of pushing to an external remote.
// NEVER add "git push" commands here.
func setupSandbox(t *testing.T) (remoteDir, workDir string) {
	t.Helper()
	temp := t.TempDir()
	seedDir := filepath.Join(temp, "seed")
	remoteDir = filepath.Join(temp, "remote.git")
	workDir = filepath.Join(temp, "work")

	// 1. Initialize seed repository to create commits and branches
	runGitCmd(t, temp, "init", "-b", "main", seedDir)
	runGitCmd(t, seedDir, "config", "user.name", "Tester")
	runGitCmd(t, seedDir, "config", "user.email", "tester@example.com")

	// Create initial commit on main
	testFile := filepath.Join(seedDir, "README.md")
	if err := os.WriteFile(testFile, []byte("Initial main"), 0o644); err != nil {
		t.Fatalf("failed to write test file: %v", err)
	}
	runGitCmd(t, seedDir, "add", "README.md")
	runGitCmd(t, seedDir, "commit", "-m", "Initial commit on main")

	// Create topic branch and commit
	runGitCmd(t, seedDir, "checkout", "-b", "topic")
	topicFile := filepath.Join(seedDir, "topic.txt")
	if err := os.WriteFile(topicFile, []byte("Topic feature"), 0o644); err != nil {
		t.Fatalf("failed to write topic file: %v", err)
	}
	runGitCmd(t, seedDir, "add", "topic.txt")
	runGitCmd(t, seedDir, "commit", "-m", "Commit on topic")

	// Ensure seed repository HEAD points to main as default branch
	runGitCmd(t, seedDir, "checkout", "main")

	// 2. Clone seed as bare remote (creates remote.git without any "git push")
	runGitCmd(t, temp, "clone", "--bare", seedDir, remoteDir)

	// 3. Clone bare remote to workDir
	runGitCmd(t, temp, "clone", remoteDir, workDir)
	runGitCmd(t, workDir, "config", "user.name", "Tester")
	runGitCmd(t, workDir, "config", "user.email", "tester@example.com")
	runGitCmd(t, workDir, "checkout", "main")

	return remoteDir, workDir
}

func Test_run_Sandbox(t *testing.T) {
	t.Run("resets current branch when no argument is given", func(t *testing.T) {
		_, workDir := setupSandbox(t)

		// Record the remote commit hash on main
		remoteMainHash := runGitCmd(t, workDir, "rev-parse", "origin/main")

		// Add an unwanted local commit on main
		testFile := filepath.Join(workDir, "README.md")
		if err := os.WriteFile(testFile, []byte("Unwanted local change"), 0o644); err != nil {
			t.Fatalf("failed to write file: %v", err)
		}
		runGitCmd(t, workDir, "commit", "-a", "-m", "Unwanted local commit")
		localUnwantedHash := runGitCmd(t, workDir, "rev-parse", "HEAD")

		if localUnwantedHash == remoteMainHash {
			t.Fatal("local commit should differ from remote commit")
		}

		// Run git-reset-branch without args on main
		var stdout, stderr bytes.Buffer
		if err := run([]string{}, workDir, &stdout, &stderr); err != nil {
			t.Fatalf("run failed: %v, stderr: %s", err, stderr.String())
		}

		// Verify main is reset to remote commit
		newHead := runGitCmd(t, workDir, "rev-parse", "HEAD")
		if newHead != remoteMainHash {
			t.Errorf("HEAD is %s, want %s (origin/main)", newHead, remoteMainHash)
		}

		// Verify backup branch exists and points to unwanted commit
		branches := runGitCmd(t, workDir, "branch", "--list", "backup-main-*")
		branchList := strings.Fields(branches)
		if len(branchList) == 0 {
			t.Fatalf("expected backup branch backup-main-*, got none")
		}
		backupBranch := strings.TrimPrefix(branchList[0], "*")
		backupBranch = strings.TrimSpace(backupBranch)
		backupHash := runGitCmd(t, workDir, "rev-parse", backupBranch)
		if backupHash != localUnwantedHash {
			t.Errorf("backup branch points to %s, want %s", backupHash, localUnwantedHash)
		}
	})

	t.Run("resets specified branch when given as argument even from another branch", func(t *testing.T) {
		_, workDir := setupSandbox(t)

		// Switch to topic branch and add unwanted commit
		runGitCmd(t, workDir, "checkout", "topic")
		remoteTopicHash := runGitCmd(t, workDir, "rev-parse", "origin/topic")

		topicFile := filepath.Join(workDir, "topic.txt")
		if err := os.WriteFile(topicFile, []byte("Unwanted topic change"), 0o644); err != nil {
			t.Fatalf("failed to write file: %v", err)
		}
		runGitCmd(t, workDir, "commit", "-a", "-m", "Unwanted topic commit")
		unwantedTopicHash := runGitCmd(t, workDir, "rev-parse", "HEAD")

		// Switch back to main
		runGitCmd(t, workDir, "checkout", "main")

		// Run git-reset-branch topic from main
		var stdout, stderr bytes.Buffer
		if err := run([]string{"topic"}, workDir, &stdout, &stderr); err != nil {
			t.Fatalf("run failed: %v, stderr: %s", err, stderr.String())
		}

		// Verify topic branch is reset to remote
		topicHash := runGitCmd(t, workDir, "rev-parse", "topic")
		if topicHash != remoteTopicHash {
			t.Errorf("topic is %s, want %s (origin/topic)", topicHash, remoteTopicHash)
		}

		// Verify backup branch exists
		branches := runGitCmd(t, workDir, "branch", "--list", "backup-topic-*")
		branchList := strings.Fields(branches)
		if len(branchList) == 0 {
			t.Fatalf("expected backup branch backup-topic-*, got none")
		}
		backupBranch := strings.TrimPrefix(branchList[0], "*")
		backupBranch = strings.TrimSpace(backupBranch)
		backupHash := runGitCmd(t, workDir, "rev-parse", backupBranch)
		if backupHash != unwantedTopicHash {
			t.Errorf("backup branch points to %s, want %s", backupHash, unwantedTopicHash)
		}
	})

	t.Run("fails safely when working tree is dirty", func(t *testing.T) {
		_, workDir := setupSandbox(t)

		testFile := filepath.Join(workDir, "README.md")
		if err := os.WriteFile(testFile, []byte("Dirty change"), 0o644); err != nil {
			t.Fatalf("failed to write file: %v", err)
		}

		var stdout, stderr bytes.Buffer
		err := run([]string{}, workDir, &stdout, &stderr)
		if err == nil {
			t.Fatal("expected error on dirty working tree, got nil")
		}
		if !strings.Contains(err.Error(), "uncommitted changes") {
			t.Errorf("error = %q, want error mentioning uncommitted changes", err.Error())
		}
	})

	t.Run("fails safely when remote branch does not exist", func(t *testing.T) {
		_, workDir := setupSandbox(t)

		var stdout, stderr bytes.Buffer
		err := run([]string{"non-existent-branch"}, workDir, &stdout, &stderr)
		if err == nil {
			t.Fatal("expected error on non-existent branch, got nil")
		}
	})

	t.Run("supports dry-run mode without modifying branches", func(t *testing.T) {
		_, workDir := setupSandbox(t)

		headBefore := runGitCmd(t, workDir, "rev-parse", "HEAD")

		var stdout, stderr bytes.Buffer
		if err := run([]string{"--dry-run"}, workDir, &stdout, &stderr); err != nil {
			t.Fatalf("run failed in dry-run: %v", err)
		}

		headAfter := runGitCmd(t, workDir, "rev-parse", "HEAD")
		if headBefore != headAfter {
			t.Errorf("HEAD changed in dry-run mode: before %s, after %s", headBefore, headAfter)
		}
		if !strings.Contains(stdout.String(), "[dry-run]") {
			t.Errorf("expected dry-run output, got: %s", stdout.String())
		}
	})
}

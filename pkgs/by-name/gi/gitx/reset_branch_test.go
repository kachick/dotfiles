package main

import (
	"bytes"
	"path/filepath"
	"strings"
	"testing"
)

// setupResetSandbox creates an isolated test environment without running "git push".
//
// Why not git push:
// Even in sandboxed local tests, avoid running "git push" commands entirely.
// We seed commits into a local repository first and create the bare remote via "git clone --bare",
// which eliminates any accidental risk or fear of pushing to an external remote.
// NEVER add "git push" commands here.
func setupResetSandbox(t *testing.T) (remoteDir, workDir string) {
	t.Helper()
	temp := t.TempDir()
	seedDir := filepath.Join(temp, "seed")
	remoteDir = filepath.Join(temp, "remote.git")
	workDir = filepath.Join(temp, "work")

	runGit(t, temp, "init", "-b", "main", seedDir)
	runGit(t, seedDir, "config", "user.name", "Tester")
	runGit(t, seedDir, "config", "user.email", "tester@example.com")

	writeTestFile(t, filepath.Join(seedDir, "README.md"), "Initial main")
	runGit(t, seedDir, "add", "README.md")
	runGit(t, seedDir, "commit", "-m", "Initial commit on main")

	runGit(t, seedDir, "checkout", "-b", "topic")
	writeTestFile(t, filepath.Join(seedDir, "topic.txt"), "Topic feature")
	runGit(t, seedDir, "add", "topic.txt")
	runGit(t, seedDir, "commit", "-m", "Commit on topic")

	runGit(t, seedDir, "checkout", "main")

	runGit(t, temp, "clone", "--bare", seedDir, remoteDir)
	runGit(t, temp, "clone", remoteDir, workDir)
	runGit(t, workDir, "config", "user.name", "Tester")
	runGit(t, workDir, "config", "user.email", "tester@example.com")
	runGit(t, workDir, "checkout", "main")

	return remoteDir, workDir
}

func TestRunResetBranch_Sandbox(t *testing.T) {
	t.Run("resets current branch when no argument is given", func(t *testing.T) {
		isolateEnv(t)
		_, workDir := setupResetSandbox(t)

		remoteMainHash := runGit(t, workDir, "rev-parse", "origin/main")

		writeTestFile(t, filepath.Join(workDir, "README.md"), "Unwanted local change")
		runGit(t, workDir, "commit", "-a", "-m", "Unwanted local commit")
		localUnwantedHash := runGit(t, workDir, "rev-parse", "HEAD")

		if localUnwantedHash == remoteMainHash {
			t.Fatal("local commit should differ from remote commit")
		}

		var stdout, stderr bytes.Buffer
		if err := runResetBranch([]string{}, workDir, &stdout, &stderr); err != nil {
			t.Fatalf("run failed: %v, stderr: %s", err, stderr.String())
		}

		newHead := runGit(t, workDir, "rev-parse", "HEAD")
		if newHead != remoteMainHash {
			t.Errorf("HEAD is %s, want %s (origin/main)", newHead, remoteMainHash)
		}

		branches := runGit(t, workDir, "branch", "--list", "backup-main-*")
		branchList := strings.Fields(branches)
		if len(branchList) == 0 {
			t.Fatalf("expected backup branch backup-main-*, got none")
		}
		backupBranch := strings.TrimSpace(strings.TrimPrefix(branchList[0], "*"))
		backupHash := runGit(t, workDir, "rev-parse", backupBranch)
		if backupHash != localUnwantedHash {
			t.Errorf("backup branch points to %s, want %s", backupHash, localUnwantedHash)
		}
	})

	t.Run("resets specified branch when given as argument even from another branch", func(t *testing.T) {
		isolateEnv(t)
		_, workDir := setupResetSandbox(t)

		runGit(t, workDir, "checkout", "topic")
		remoteTopicHash := runGit(t, workDir, "rev-parse", "origin/topic")

		writeTestFile(t, filepath.Join(workDir, "topic.txt"), "Unwanted topic change")
		runGit(t, workDir, "commit", "-a", "-m", "Unwanted topic commit")
		unwantedTopicHash := runGit(t, workDir, "rev-parse", "HEAD")

		runGit(t, workDir, "checkout", "main")

		var stdout, stderr bytes.Buffer
		if err := runResetBranch([]string{"topic"}, workDir, &stdout, &stderr); err != nil {
			t.Fatalf("run failed: %v, stderr: %s", err, stderr.String())
		}

		topicHash := runGit(t, workDir, "rev-parse", "topic")
		if topicHash != remoteTopicHash {
			t.Errorf("topic is %s, want %s (origin/topic)", topicHash, remoteTopicHash)
		}

		branches := runGit(t, workDir, "branch", "--list", "backup-topic-*")
		branchList := strings.Fields(branches)
		if len(branchList) == 0 {
			t.Fatalf("expected backup branch backup-topic-*, got none")
		}
		backupBranch := strings.TrimSpace(strings.TrimPrefix(branchList[0], "*"))
		backupHash := runGit(t, workDir, "rev-parse", backupBranch)
		if backupHash != unwantedTopicHash {
			t.Errorf("backup branch points to %s, want %s", backupHash, unwantedTopicHash)
		}
	})

	t.Run("fails safely when working tree is dirty", func(t *testing.T) {
		isolateEnv(t)
		_, workDir := setupResetSandbox(t)

		writeTestFile(t, filepath.Join(workDir, "README.md"), "Dirty change")

		var stdout, stderr bytes.Buffer
		err := runResetBranch([]string{}, workDir, &stdout, &stderr)
		if err == nil {
			t.Fatal("expected error on dirty working tree, got nil")
		}
		if !strings.Contains(err.Error(), "uncommitted changes") {
			t.Errorf("error = %q, want error mentioning uncommitted changes", err.Error())
		}
	})

	t.Run("fails safely when remote branch does not exist", func(t *testing.T) {
		isolateEnv(t)
		_, workDir := setupResetSandbox(t)

		var stdout, stderr bytes.Buffer
		err := runResetBranch([]string{"non-existent-branch"}, workDir, &stdout, &stderr)
		if err == nil {
			t.Fatal("expected error on non-existent branch, got nil")
		}
	})

	t.Run("supports dry-run mode without modifying branches", func(t *testing.T) {
		isolateEnv(t)
		_, workDir := setupResetSandbox(t)

		headBefore := runGit(t, workDir, "rev-parse", "HEAD")

		var stdout, stderr bytes.Buffer
		if err := runResetBranch([]string{"--dry-run"}, workDir, &stdout, &stderr); err != nil {
			t.Fatalf("run failed in dry-run: %v", err)
		}

		headAfter := runGit(t, workDir, "rev-parse", "HEAD")
		if headBefore != headAfter {
			t.Errorf("HEAD changed in dry-run mode: before %s, after %s", headBefore, headAfter)
		}
		if !strings.Contains(stdout.String(), "[dry-run]") {
			t.Errorf("expected dry-run output, got: %s", stdout.String())
		}
	})
}

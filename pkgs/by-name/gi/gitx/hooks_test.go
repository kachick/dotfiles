package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestInitializeLinters(t *testing.T) {
	t.Run("returns linters covering title, message body, and diff against secrets and typos", func(t *testing.T) {
		line := "refs/heads/feature 1111111111111111111111111111111111111111 refs/heads/feature 2222222222222222222222222222222222222222"
		linters, err := initializeLinters(line, "main", "dev@example.com")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if len(linters) != 3 {
			t.Fatalf("got %d linters, want 3", len(linters))
		}

		expectedKeyTags := map[string]string{
			"prevent secrets in log and diff": "betterleaks",
			"prevent typos in log and diff":   "typos-commits",
			"prevent typos in branch name":    "typos-branch",
		}

		for key, wantTag := range expectedKeyTags {
			linter, ok := linters[key]
			if !ok {
				t.Errorf("missing expected linter key: %q", key)
				continue
			}
			if linter.Tag != wantTag {
				t.Errorf("linter %q tag = %q, want %q", key, linter.Tag, wantTag)
			}
		}
	})

	t.Run("skips deleted ref when localRef is (delete)", func(t *testing.T) {
		line := "(delete) 0000000000000000000000000000000000000000 refs/heads/feature 2222222222222222222222222222222222222222"
		linters, err := initializeLinters(line, "main", "dev@example.com")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if linters != nil {
			t.Errorf("got %v, want nil for deleted ref", linters)
		}
	})

	t.Run("skips deleted ref when localOid is SHA-1 zero OID", func(t *testing.T) {
		line := "refs/heads/feature " + zeroOIDSHA1 + " refs/heads/feature 2222222222222222222222222222222222222222"
		linters, err := initializeLinters(line, "main", "dev@example.com")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if linters != nil {
			t.Errorf("got %v, want nil for SHA-1 zero oid", linters)
		}
	})

	t.Run("skips deleted ref when localOid is SHA-256 zero OID", func(t *testing.T) {
		line := "refs/heads/feature " + zeroOIDSHA256 + " refs/heads/feature 2222222222222222222222222222222222222222"
		linters, err := initializeLinters(line, "main", "dev@example.com")
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if linters != nil {
			t.Errorf("got %v, want nil for SHA-256 zero oid", linters)
		}
	})

	t.Run("returns error on invalid line format", func(t *testing.T) {
		line := "invalid input"
		_, err := initializeLinters(line, "main", "dev@example.com")
		if err == nil {
			t.Fatal("expected error on invalid input, got nil")
		}
	})
}

func TestRunPipedCommands(t *testing.T) {
	t.Run("passes stdout of first command to stdin of second command", func(t *testing.T) {
		out, err := runPipedCommands(
			[]string{"echo", "hello world"},
			[]string{"tr", "a-z", "A-Z"},
		)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if got := string(out); got != "HELLO WORLD\n" {
			t.Errorf("got %q, want %q", got, "HELLO WORLD\n")
		}
	})

	t.Run("returns error when first command fails", func(t *testing.T) {
		_, err := runPipedCommands(
			[]string{"false"},
			[]string{"cat"},
		)
		if err == nil {
			t.Fatal("expected error when first command fails, got nil")
		}
	})
}

func TestExtractAddedDiffLines(t *testing.T) {
	truncatedWord := "er" + "ro"
	oldTypo := "rec" + "iev" + "e"

	t.Run("extracts only added hunk lines and drops truncated hunk headers, metadata, and deletions", func(t *testing.T) {
		patch := strings.Join([]string{
			"diff --git a/internal/gitcmd/gitcmd.go b/internal/gitcmd/gitcmd.go",
			"index 28a48b03..bee13bd1 100644",
			"--- a/internal/gitcmd/gitcmd.go",
			"+++ b/internal/gitcmd/gitcmd.go",
			"@@ -218 +218 @@ func DetectDefaultBranch(r *Runner, commonDir string, isBare bool) (string, " + truncatedWord,
			"-\t// " + oldTypo + " old typo",
			"+\t// receive fixed line",
			"+++added heading",
			`\ No newline at end of file`,
			"diff --git a/other.txt b/other.txt",
			"new file mode 100644",
			"index 0000000..1111111",
			"--- /dev/null",
			"+++ b/other.txt",
			"@@ -0,0 +1 @@",
			"+plain added line",
		}, "\n") + "\n"

		got, err := extractAddedDiffLines(strings.NewReader(patch))
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		want := "\t// receive fixed line\n++added heading\nplain added line\n"
		if string(got) != want {
			t.Errorf("got:\n%q\nwant:\n%q", string(got), want)
		}
	})

	t.Run("handles added lines exceeding default bufio.Scanner token limit", func(t *testing.T) {
		longBody := strings.Repeat("a", 80*1024)
		patch := "diff --git a/long.txt b/long.txt\n@@ -0,0 +1 @@\n+" + longBody + "\n"

		got, err := extractAddedDiffLines(strings.NewReader(patch))
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if string(got) != longBody+"\n" {
			t.Errorf("got length %d, want %d", len(got), len(longBody)+1)
		}
	})
}

func TestCheckCommitsTypos(t *testing.T) {
	truncatedWord := "er" + "ro"
	oldTypo := "rec" + "iev" + "e"

	t.Run("sends commit messages and added lines to typos without hunk headers or deleted lines", func(t *testing.T) {
		isolateEnv(t)

		temp := t.TempDir()
		repoDir := filepath.Join(temp, "repo")
		runGit(t, temp, "init", "-b", "main", repoDir)
		runGit(t, repoDir, "config", "user.name", "Tester")
		runGit(t, repoDir, "config", "user.email", "dev@example.com")

		sourcePath := filepath.Join(repoDir, "sample.go")
		writeTestFile(t, sourcePath, strings.Join([]string{
			"package sample",
			"",
			"func DetectDefaultBranch(r *Runner, commonDir string, isBare bool) (string, error) {",
			"\t// " + oldTypo + " old typo",
			"\treturn \"main\", nil",
			"}",
			"",
		}, "\n"))
		runGit(t, repoDir, "add", "sample.go")
		runGit(t, repoDir, "commit", "--no-gpg-sign", "-m", "Add initial sample")
		baseCommit := runGit(t, repoDir, "rev-parse", "HEAD")

		writeTestFile(t, sourcePath, strings.Join([]string{
			"package sample",
			"",
			"func DetectDefaultBranch(r *Runner, commonDir string, isBare bool) (string, error) {",
			"\t// receive fixed comment",
			"\treturn \"main\", nil",
			"}",
			"",
		}, "\n"))
		runGit(t, repoDir, "add", "sample.go")
		runGit(t, repoDir, "commit", "--no-gpg-sign", "-m", "Fix comment spelling")

		binDir := filepath.Join(temp, "bin")
		capturedInput := filepath.Join(temp, "typos-stdin.txt")
		fakeTypos := filepath.Join(binDir, "typos")
		writeTestFile(t, fakeTypos, "#!/bin/sh\ncat > \""+capturedInput+"\"\n")
		if err := os.Chmod(fakeTypos, 0o755); err != nil {
			t.Fatalf("chmod fake typos: %v", err)
		}

		origConfigPath := TyposConfigPath
		TyposConfigPath = filepath.Join(temp, "typos.toml")
		t.Cleanup(func() {
			TyposConfigPath = origConfigPath
		})
		t.Setenv("PATH", binDir+string(os.PathListSeparator)+os.Getenv("PATH"))
		t.Chdir(repoDir)

		if out, err := checkCommitsTypos(baseCommit, "HEAD", "dev@example.com"); err != nil {
			t.Fatalf("checkCommitsTypos failed: %v: %s", err, string(out))
		}

		got := readTestFile(t, capturedInput)
		if !strings.Contains(got, "Fix comment spelling") {
			t.Errorf("expected commit message in typos input, got:\n%s", got)
		}
		if !strings.Contains(got, "// receive fixed comment") {
			t.Errorf("expected added diff line in typos input, got:\n%s", got)
		}
		for _, unwanted := range []string{"@@", "DetectDefaultBranch", truncatedWord, oldTypo, "diff --git"} {
			if strings.Contains(got, unwanted) {
				t.Errorf("unexpected %q in typos input:\n%s", unwanted, got)
			}
		}
	})
}

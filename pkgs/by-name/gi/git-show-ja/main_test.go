package main

import (
	"os/exec"
	"strings"
	"testing"
)

func TestBuildSystemPrompt(t *testing.T) {
	got := buildSystemPrompt("")
	want := "[plamo-translate]\ntarget_lang=ja\nform=plain"
	if got != want {
		t.Errorf("buildSystemPrompt(\"\") = %q, want %q", got, want)
	}

	gotWithContext := buildSystemPrompt("Git commit message")
	wantWithContext := "[plamo-translate]\ntarget_lang=ja\nform=plain\n---\nGit commit message"
	if gotWithContext != wantWithContext {
		t.Errorf("buildSystemPrompt(ctx) = %q, want %q", gotWithContext, wantWithContext)
	}
}

func TestBuildCommitContext(t *testing.T) {
	// For invalid ref, it should fall back to "Git commit message"
	got := buildCommitContext("invalid-non-existent-ref-000", "")
	if got != "Git commit message" {
		t.Errorf("expected fallback context for invalid ref, got: %q", got)
	}

	// For HEAD, it should retrieve commit message and changed files
	gotHead := buildCommitContext("HEAD", "")
	if !strings.HasPrefix(gotHead, "Git commit message") {
		t.Errorf("expected context to start with 'Git commit message', got: %q", gotHead)
	}
}

func TestParseArgs(t *testing.T) {
	tests := []struct {
		name            string
		args            []string
		wantRef         string
		wantPlaceholder string
		wantGitArgs     []string
	}{
		{
			name:            "empty args",
			args:            []string{},
			wantRef:         "HEAD",
			wantPlaceholder: "",
			wantGitArgs:     nil,
		},
		{
			name:            "placeholder flag with space",
			args:            []string{"--placeholder", "翻訳中...", "HEAD~1"},
			wantRef:         "HEAD~1",
			wantPlaceholder: "翻訳中...",
			wantGitArgs:     []string{"HEAD~1"},
		},
		{
			name:            "placeholder flag with equal",
			args:            []string{"--placeholder=翻訳中...", "--stat"},
			wantRef:         "HEAD",
			wantPlaceholder: "翻訳中...",
			wantGitArgs:     []string{"--stat"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parseArgs(tt.args)
			if got.ref != tt.wantRef {
				t.Errorf("parseArgs().ref = %q, want %q", got.ref, tt.wantRef)
			}
			if got.placeholder != tt.wantPlaceholder {
				t.Errorf("parseArgs().placeholder = %q, want %q", got.placeholder, tt.wantPlaceholder)
			}
			if len(got.gitArgs) != len(tt.wantGitArgs) {
				t.Errorf("parseArgs().gitArgs = %v, want %v", got.gitArgs, tt.wantGitArgs)
			}
		})
	}
}

func TestRun_Placeholder(t *testing.T) {
	if _, err := exec.LookPath("git"); err != nil {
		t.Skip("git not found in PATH")
	}
	if err := exec.Command("git", "rev-parse", "--git-dir").Run(); err != nil {
		t.Skip("not running inside a git repository")
	}

	var stdout, stderr strings.Builder
	err := run([]string{"--placeholder", "翻訳待機中...", "HEAD"}, "", &stdout, &stderr)
	if err != nil {
		t.Fatalf("run with --placeholder failed: %v", err)
	}
	out := stdout.String()
	if !strings.Contains(out, "<ja>") || !strings.Contains(out, "翻訳待機中...") || !strings.Contains(out, "</ja>") {
		t.Errorf("expected placeholder in output, got: %s", out)
	}
}

func TestExtractRef(t *testing.T) {
	tests := []struct {
		name string
		args []string
		want string
	}{
		{"empty args", []string{}, "HEAD"},
		{"single ref", []string{"main"}, "main"},
		{"flags before ref", []string{"--stat", "abc1234"}, "abc1234"},
		{"only flags", []string{"--stat", "--color=always"}, "HEAD"},
		{"ref with flags after", []string{"HEAD~1", "--stat"}, "HEAD~1"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := extractRef(tt.args)
			if got != tt.want {
				t.Errorf("extractRef(%v) = %q, want %q", tt.args, got, tt.want)
			}
		})
	}
}

func TestFormatTranslationBlock(t *testing.T) {
	input := "タイトル\n\n- 箇条書き1\n- 箇条書き2"
	got := formatTranslationBlock(input)

	if !strings.HasPrefix(got, cyan+"<ja>"+reset) {
		t.Errorf("expected <ja> opening tag, got: %s", got)
	}
	if !strings.HasSuffix(got, cyan+"</ja>"+reset) {
		t.Errorf("expected </ja> closing tag, got: %s", got)
	}
	// Check that lines have cyan coloring
	if !strings.Contains(got, cyan+"タイトル"+reset) {
		t.Errorf("expected line to be cyan, got: %s", got)
	}
	// Check that empty lines remain empty without color codes
	if !strings.Contains(got, "\n\n") {
		t.Errorf("expected empty line to be preserved, got: %s", got)
	}
}

func TestInjectTranslation(t *testing.T) {
	t.Run("with diff", func(t *testing.T) {
		gitShow := "commit 1234567\nAuthor: John\nDate: 2026-01-01\n\n    Subject\n\n    Body line\n\ndiff --git a/file b/file\nindex 111..222 100644\n--- a/file\n+++ b/file\n@@ -1 +1 @@\n-old\n+new"
		block := "<ja>\n翻訳テキスト\n</ja>"

		got := injectTranslation(gitShow, block)

		if !strings.Contains(got, "    Body line\n\n<ja>\n翻訳テキスト\n</ja>\n\ndiff --git a/file b/file") {
			t.Errorf("unexpected placement of translation block:\n%s", got)
		}
	})

	t.Run("empty commit without diff", func(t *testing.T) {
		gitShow := "commit 1234567\nAuthor: John\nDate: 2026-01-01\n\n    Empty commit"
		block := "<ja>\n空コミット\n</ja>"

		got := injectTranslation(gitShow, block)

		if !strings.HasSuffix(got, "\n\n<ja>\n空コミット\n</ja>") {
			t.Errorf("expected block at the end of git show, got:\n%s", got)
		}
	})
}

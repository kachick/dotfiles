package main

import (
	"bytes"
	"path/filepath"
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
	got := buildCommitContext("invalid-non-existent-ref-000", "")
	if got != "Git commit message" {
		t.Errorf("expected fallback context for invalid ref, got: %q", got)
	}

	isolateEnv(t)
	repoDir := filepath.Join(t.TempDir(), "repo")
	initSeedRepo(t, repoDir, "main")

	gotHead := buildCommitContext("HEAD", repoDir)
	if !strings.HasPrefix(gotHead, "Git commit message") {
		t.Errorf("expected context to start with 'Git commit message', got: %q", gotHead)
	}
}

func TestParseShowArgs(t *testing.T) {
	tests := []struct {
		name            string
		args            []string
		wantJa          bool
		wantRef         string
		wantPlaceholder string
		wantGitArgs     []string
	}{
		{
			name:            "empty args",
			args:            []string{},
			wantJa:          false,
			wantRef:         "HEAD",
			wantPlaceholder: "",
			wantGitArgs:     nil,
		},
		{
			name:            "ja flag with placeholder and ref",
			args:            []string{"--ja", "--placeholder", "翻訳中...", "HEAD~1"},
			wantJa:          true,
			wantRef:         "HEAD~1",
			wantPlaceholder: "翻訳中...",
			wantGitArgs:     []string{"HEAD~1"},
		},
		{
			name:            "ja flag with placeholder equal and git flag",
			args:            []string{"--ja", "--placeholder=翻訳中...", "--stat"},
			wantJa:          true,
			wantRef:         "HEAD",
			wantPlaceholder: "翻訳中...",
			wantGitArgs:     []string{"--stat"},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := parseShowArgs(tt.args)
			if got.ja != tt.wantJa {
				t.Errorf("parseShowArgs().ja = %v, want %v", got.ja, tt.wantJa)
			}
			if got.ref != tt.wantRef {
				t.Errorf("parseShowArgs().ref = %q, want %q", got.ref, tt.wantRef)
			}
			if got.placeholder != tt.wantPlaceholder {
				t.Errorf("parseShowArgs().placeholder = %q, want %q", got.placeholder, tt.wantPlaceholder)
			}
			if len(got.gitArgs) != len(tt.wantGitArgs) {
				t.Errorf("parseShowArgs().gitArgs = %v, want %v", got.gitArgs, tt.wantGitArgs)
			}
		})
	}
}

func TestRunShow_PlaceholderAndPlain(t *testing.T) {
	isolateEnv(t)
	repoDir := filepath.Join(t.TempDir(), "repo")
	initSeedRepo(t, repoDir, "main")

	var stdout, stderr bytes.Buffer
	if err := runShow([]string{"--ja", "--placeholder", "翻訳待機中...", "HEAD"}, repoDir, strings.NewReader(""), &stdout, &stderr); err != nil {
		t.Fatalf("runShow --ja --placeholder failed: %v", err)
	}
	out := stdout.String()
	if !strings.Contains(out, "<ja>") || !strings.Contains(out, "翻訳待機中...") || !strings.Contains(out, "</ja>") {
		t.Errorf("expected placeholder in output, got: %s", out)
	}

	stdout.Reset()
	stderr.Reset()
	if err := runShow([]string{"--stat", "HEAD"}, repoDir, strings.NewReader(""), &stdout, &stderr); err != nil {
		t.Fatalf("runShow plain failed: %v", err)
	}
	if strings.Contains(stdout.String(), "<ja>") || !strings.Contains(stdout.String(), "Initial commit") {
		t.Errorf("unexpected plain show output:\n%s", stdout.String())
	}
}

func TestExtractShowRef(t *testing.T) {
	tests := []struct {
		name string
		args []string
		want string
	}{
		{"empty args", []string{}, "HEAD"},
		{"single ref", []string{"main"}, "main"},
		{"flags before ref", []string{"--ja", "--stat", "abc1234"}, "abc1234"},
		{"only flags", []string{"--stat", "--color=always"}, "HEAD"},
		{"ref with flags after", []string{"HEAD~1", "--stat"}, "HEAD~1"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := extractShowRef(tt.args)
			if got != tt.want {
				t.Errorf("extractShowRef(%v) = %q, want %q", tt.args, got, tt.want)
			}
		})
	}
}

func TestFormatTranslationBlock(t *testing.T) {
	input := "タイトル\n\n- 箇条書き1\n- 箇条書き2"
	got := formatTranslationBlock(input)

	if !strings.HasPrefix(got, ansiCyan+"<ja>"+ansiReset) {
		t.Errorf("expected <ja> opening tag, got: %s", got)
	}
	if !strings.HasSuffix(got, ansiCyan+"</ja>"+ansiReset) {
		t.Errorf("expected </ja> closing tag, got: %s", got)
	}
	if !strings.Contains(got, ansiCyan+"タイトル"+ansiReset) {
		t.Errorf("expected line to be cyan, got: %s", got)
	}
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

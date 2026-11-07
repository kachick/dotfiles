package main

import (
	"strings"
	"testing"
)

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

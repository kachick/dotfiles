package main

import (
	"bytes"
	"path/filepath"
	"slices"
	"strings"
	"testing"
)

func TestTrimHistoryLines(t *testing.T) {
	testCases := map[string]struct {
		input string
		want  string
	}{
		"trims tabs and spaces and drops blank lines": {
			input: "\t git status  \n  \n  cargo test\n\n   \t\n",
			want:  "git status\ncargo test\n",
		},
		"returns empty string for blank input": {
			input: "  \n\t\n",
			want:  "",
		},
		"returns empty string for empty input": {
			input: "",
			want:  "",
		},
	}

	for name, tc := range testCases {
		t.Run(name, func(t *testing.T) {
			got := trimHistoryLines(strings.NewReader(tc.input))
			if got != tc.want {
				t.Errorf("trimHistoryLines(%q) = %q, want %q", tc.input, got, tc.want)
			}
		})
	}
}

func TestFormatBacktickCommitMessage(t *testing.T) {
	testCases := map[string]struct {
		input string
		want  string
	}{
		"preserves dollar signs and double quotes": {
			input: `echo "$HOME"`,
			want:  "`echo \"$HOME\"`\n",
		},
		"preserves backticks and hashes": {
			input: "  nix build .#gitx && echo `date`  ",
			want:  "`nix build .#gitx && echo `date``\n",
		},
	}

	for name, tc := range testCases {
		t.Run(name, func(t *testing.T) {
			got := formatBacktickCommitMessage(tc.input)
			if got != tc.want {
				t.Errorf("formatBacktickCommitMessage(%q) = %q, want %q", tc.input, got, tc.want)
			}
		})
	}
}

func TestCommitFromHistoryFzfArgs(t *testing.T) {
	t.Run("uses 40% height by default", func(t *testing.T) {
		t.Setenv("FZF_TMUX_HEIGHT", "")
		got := commitFromHistoryFzfArgs()
		want := []string{"--height=40%", "-n2..,..", "--scheme=history"}
		if !slices.Equal(got, want) {
			t.Errorf("commitFromHistoryFzfArgs() = %v, want %v", got, want)
		}
	})

	t.Run("respects FZF_TMUX_HEIGHT", func(t *testing.T) {
		t.Setenv("FZF_TMUX_HEIGHT", "60%")
		got := commitFromHistoryFzfArgs()
		want := []string{"--height=60%", "-n2..,..", "--scheme=history"}
		if !slices.Equal(got, want) {
			t.Errorf("commitFromHistoryFzfArgs() = %v, want %v", got, want)
		}
	})
}

func TestRunCommitFromHistoryValidation(t *testing.T) {
	t.Run("rejects positional arguments", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		err := runCommitFromHistory([]string{"extra"}, "", strings.NewReader("git status\n"), &stdout, &stderr)
		if err == nil {
			t.Fatal("expected error for positional argument, got nil")
		}
	})

	t.Run("returns nil on empty stdin", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		err := runCommitFromHistory(nil, "", strings.NewReader("   \n\t\n"), &stdout, &stderr)
		if err != nil {
			t.Fatalf("expected nil on empty stdin, got %v", err)
		}
	})
}

func TestCommitWithBacktickMessage(t *testing.T) {
	isolateEnv(t)
	repoDir := t.TempDir()

	runGit(t, repoDir, "init", "-b", "main")
	runGit(t, repoDir, "config", "user.name", "Tester")
	runGit(t, repoDir, "config", "user.email", "tester@example.com")
	writeTestFile(t, filepath.Join(repoDir, "notes.txt"), "before\n")
	runGit(t, repoDir, "add", ".")
	runGit(t, repoDir, "commit", "-m", "Initial commit")

	writeTestFile(t, filepath.Join(repoDir, "notes.txt"), "after\n")

	var stdout, stderr bytes.Buffer
	selected := `echo "$HOME" && nix build .#gitx`
	if err := commitWithBacktickMessage(repoDir, selected, &stdout, &stderr); err != nil {
		t.Fatalf("commitWithBacktickMessage failed: %v, stderr: %s", err, stderr.String())
	}

	gotSubject := runGit(t, repoDir, "log", "-1", "--format=%s")
	wantSubject := "`" + selected + "`"
	if gotSubject != wantSubject {
		t.Errorf("commit subject = %q, want %q", gotSubject, wantSubject)
	}

	if status := runGit(t, repoDir, "status", "--porcelain"); status != "" {
		t.Errorf("expected clean working tree after --all commit, got %q", status)
	}
}

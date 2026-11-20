package main

import (
	"bytes"
	"errors"
	"flag"
	"os/exec"
	"slices"
	"strconv"
	"strings"
	"testing"
)

func TestRunCompletion(t *testing.T) {
	t.Run("generates bash and zsh scripts", func(t *testing.T) {
		for _, shell := range supportedCompletionShells() {
			var stdout, stderr bytes.Buffer
			if err := runGitx([]string{"completion", shell}, strings.NewReader(""), &stdout, &stderr); err != nil {
				t.Fatalf("runGitx(completion %s) failed: %v (stderr: %s)", shell, err, stderr.String())
			}
			if stdout.Len() == 0 {
				t.Fatalf("expected non-empty completion output for %s", shell)
			}
			if stderr.Len() != 0 {
				t.Fatalf("expected empty stderr for %s, got: %s", shell, stderr.String())
			}
		}
	})

	t.Run("help flag returns ErrHelp and prints usage", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		err := runGitx([]string{"completion", "--help"}, strings.NewReader(""), &stdout, &stderr)
		if !errors.Is(err, flag.ErrHelp) {
			t.Fatalf("expected flag.ErrHelp, got %v", err)
		}
		if !strings.Contains(stderr.String(), "Usage: gitx completion") {
			t.Fatalf("expected completion usage on stderr, got: %s", stderr.String())
		}
	})

	t.Run("rejects missing, extra, or unsupported arguments", func(t *testing.T) {
		cases := [][]string{
			{"completion"},
			{"completion", "bash", "extra"},
			{"completion", "powershell"},
		}
		for _, args := range cases {
			var stdout, stderr bytes.Buffer
			if err := runGitx(args, strings.NewReader(""), &stdout, &stderr); err == nil {
				t.Fatalf("expected error for args %v, got nil", args)
			}
		}
	})
}

func TestGeneratedCompletionsMatchCommandDefinitions(t *testing.T) {
	tree := buildGitxCommandTree()
	bashScript := generateBashCompletion(tree)
	zshScript := generateZshCompletion(tree)

	for _, cmd := range allGitxSubcommands() {
		if !strings.Contains(bashScript, cmd.name) {
			t.Errorf("bash completion missing subcommand %q", cmd.name)
		}
		if !strings.Contains(zshScript, cmd.name) {
			t.Errorf("zsh completion missing subcommand %q", cmd.name)
		}
	}

	for _, sub := range allWTSubcommands() {
		if sub.hidden {
			if strings.Contains(bashScript, sub.name) {
				t.Errorf("bash completion must exclude hidden wt subcommand %q", sub.name)
			}
			if strings.Contains(zshScript, sub.name) {
				t.Errorf("zsh completion must exclude hidden wt subcommand %q", sub.name)
			}
			continue
		}
		if !strings.Contains(bashScript, sub.name) {
			t.Errorf("bash completion missing wt subcommand %q", sub.name)
		}
		if !strings.Contains(zshScript, sub.name) {
			t.Errorf("zsh completion missing wt subcommand %q", sub.name)
		}
	}

	for _, hidden := range []string{"_preview", "_preview-branch", "_preview-tag", "_preview-plain", "_detail", "--placeholder"} {
		if strings.Contains(bashScript, hidden) {
			t.Errorf("bash completion leaked internal token %q", hidden)
		}
		if strings.Contains(zshScript, hidden) {
			t.Errorf("zsh completion leaked internal token %q", hidden)
		}
	}

	expectedTokens := []string{
		"--trust",
		"--dry-run",
		"--interactive",
		"--pr",
		"--list",
		"--ja",
		"--mode",
		"--branch",
		"--base",
		"--remote",
		"pre-push",
		"betterleaks",
		"typos-commits",
		"typos-branch",
		"worktrees",
		"branches",
		"commits",
		"tags",
		"repos",
	}
	for _, token := range expectedTokens {
		if !strings.Contains(bashScript, token) {
			t.Errorf("bash completion missing %q", token)
		}
		if !strings.Contains(zshScript, token) {
			t.Errorf("zsh completion missing %q", token)
		}
	}

	if !strings.HasPrefix(zshScript, "#compdef gitx\n") {
		t.Errorf("zsh completion must start with #compdef gitx")
	}
	if !strings.Contains(bashScript, "complete -F _gitx gitx") {
		t.Errorf("bash completion must register complete -F _gitx gitx")
	}
}

func TestBashCompletionBehavior(t *testing.T) {
	bashScript := generateBashCompletion(buildGitxCommandTree())

	syntaxCmd := exec.Command("bash", "-n")
	syntaxCmd.Stdin = strings.NewReader(bashScript)
	if out, err := syntaxCmd.CombinedOutput(); err != nil {
		t.Fatalf("bash -n failed: %v\n%s", err, string(out))
	}

	cases := []struct {
		name     string
		words    string
		cword    int
		wantAll  []string
		wantNone []string
	}{
		{
			name:     "top-level subcommands",
			words:    `("gitx" "")`,
			cword:    1,
			wantAll:  []string{"menu", "wt", "get", "hooks", "completion", "help"},
			wantNone: []string{"_cd-helper"},
		},
		{
			name:    "wt subcommands",
			words:   `("gitx" "wt" "")`,
			cword:   2,
			wantAll: []string{"list", "select", "add", "path", "default-branch", "help"},
		},
		{
			name:    "wt add flags",
			words:   `("gitx" "wt" "add" "--")`,
			cword:   3,
			wantAll: []string{"--branch", "--base", "--trust", "--interactive", "--help"},
		},
		{
			name:    "menu --mode values",
			words:   `("gitx" "menu" "--mode" "")`,
			cword:   3,
			wantAll: []string{"worktrees", "branches", "commits", "tags", "repos"},
		},
		{
			name:    "menu --mode= prefix values",
			words:   `("gitx" "menu" "--mode=w")`,
			cword:   2,
			wantAll: []string{"--mode=worktrees"},
		},
		{
			name:    "completion shell argument",
			words:   `("gitx" "completion" "")`,
			cword:   2,
			wantAll: []string{"bash", "zsh"},
		},
		{
			name:    "hooks pre-push subcommands",
			words:   `("gitx" "hooks" "pre-push" "")`,
			cword:   3,
			wantAll: []string{"betterleaks", "typos-commits", "typos-branch"},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			driver := bashScript + "\n" +
				"COMP_WORDS=" + tc.words + "\n" +
				"COMP_CWORD=" + strconv.Itoa(tc.cword) + "\n" +
				"_gitx\n" +
				"printf '%s\\n' \"${COMPREPLY[@]}\"\n"

			cmd := exec.Command("bash", "-c", driver)
			out, err := cmd.CombinedOutput()
			if err != nil {
				t.Fatalf("bash completion execution failed: %v\n%s", err, string(out))
			}

			got := strings.Fields(string(out))
			for _, want := range tc.wantAll {
				if !slices.Contains(got, want) {
					t.Errorf("expected %q in COMPREPLY %v", want, got)
				}
			}
			for _, forbidden := range tc.wantNone {
				if slices.Contains(got, forbidden) {
					t.Errorf("unexpected %q in COMPREPLY %v", forbidden, got)
				}
			}
		})
	}
}

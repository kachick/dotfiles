package main

import (
	"bytes"
	"errors"
	"flag"
	"os/exec"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"testing"
)

func TestRunCompletion(t *testing.T) {
	t.Run("generates bash and zsh scripts", func(t *testing.T) {
		for _, shell := range supportedCompletionShells() {
			var stdout, stderr bytes.Buffer
			if err := runGitX([]string{"completion", shell}, strings.NewReader(""), &stdout, &stderr); err != nil {
				t.Fatalf("runGitX(completion %s) failed: %v (stderr: %s)", shell, err, stderr.String())
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
		err := runGitX([]string{"completion", "--help"}, strings.NewReader(""), &stdout, &stderr)
		if !errors.Is(err, flag.ErrHelp) {
			t.Fatalf("expected flag.ErrHelp, got %v", err)
		}
		if !strings.Contains(stderr.String(), "Usage: git x completion") {
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
			if err := runGitX(args, strings.NewReader(""), &stdout, &stderr); err == nil {
				t.Fatalf("expected error for args %v, got nil", args)
			}
		}
	})
}

func completionValues(result completionResult) []string {
	values := make([]string, 0, len(result.items))
	for _, item := range result.items {
		values = append(values, item.value)
	}
	return values
}

func TestCompleteArgsMatchesCommandDefinitions(t *testing.T) {
	tree := buildGitXCommandTree()

	t.Run("top-level includes all subcommands and excludes __complete", func(t *testing.T) {
		res := completeArgs(tree, []string{""})
		got := completionValues(res)
		for _, cmd := range allGitXSubcommands() {
			if !slices.Contains(got, cmd.name) {
				t.Errorf("missing top-level subcommand %q in %v", cmd.name, got)
			}
		}
		if !slices.Contains(got, "help") {
			t.Errorf("expected help in top-level completions, got %v", got)
		}
		if slices.Contains(got, "__complete") {
			t.Errorf("__complete must not appear in completions: %v", got)
		}
	})

	t.Run("wt includes public subcommands and excludes hidden ones", func(t *testing.T) {
		res := completeArgs(tree, []string{"wt", ""})
		got := completionValues(res)
		for _, sub := range allWTSubcommands() {
			if sub.hidden {
				if slices.Contains(got, sub.name) {
					t.Errorf("hidden wt subcommand %q leaked into completions: %v", sub.name, got)
				}
				continue
			}
			if !slices.Contains(got, sub.name) {
				t.Errorf("missing wt subcommand %q in %v", sub.name, got)
			}
		}
	})

	t.Run("filters subcommands by prefix and excludes internal tokens", func(t *testing.T) {
		res := completeArgs(tree, []string{"menu", "_"})
		if len(res.items) != 0 {
			t.Errorf("expected no internal completions for menu _, got %v", res.items)
		}

		res = completeArgs(tree, []string{"log-fzf", "_"})
		if len(res.items) != 0 {
			t.Errorf("expected no internal completions for log-fzf _, got %v", res.items)
		}

		res = completeArgs(tree, []string{"show", "--"})
		got := completionValues(res)
		if !slices.Contains(got, "--ja") {
			t.Errorf("expected --ja for show, got %v", got)
		}
		if slices.Contains(got, "--placeholder") {
			t.Errorf("internal --placeholder leaked into show completions: %v", got)
		}
	})

	t.Run("completes flags, fixed values, and directory directives", func(t *testing.T) {
		cases := []struct {
			name          string
			args          []string
			wantDirective completionDirective
			wantAll       []string
			wantAbsent    []string
		}{
			{
				name:          "wt add flags",
				args:          []string{"wt", "add", "--"},
				wantDirective: completionDirectiveNone,
				wantAll:       []string{"--branch", "--base", "--trust", "--interactive", "--help"},
			},
			{
				name:          "menu --mode values",
				args:          []string{"menu", "--mode", ""},
				wantDirective: completionDirectiveNone,
				wantAll:       []string{"worktrees", "branches", "commits", "tags", "repos"},
			},
			{
				name:          "menu --mode= prefix",
				args:          []string{"menu", "--mode=w"},
				wantDirective: completionDirectiveNone,
				wantAll:       []string{"--mode=worktrees"},
				wantAbsent:    []string{"--mode=branches"},
			},
			{
				name:          "reset-branch flags",
				args:          []string{"reset-branch", "--"},
				wantDirective: completionDirectiveNone,
				wantAll:       []string{"--remote", "--dry-run", "--help"},
			},
			{
				name:          "delete-merged-branches flags",
				args:          []string{"delete-merged-branches", "--"},
				wantDirective: completionDirectiveNone,
				wantAll:       []string{"--dry-run", "--pr"},
			},
			{
				name:          "migrate-clean-bare flags",
				args:          []string{"migrate-clean-bare", "--"},
				wantDirective: completionDirectiveNone,
				wantAll:       []string{"--dry-run", "--trust", "--interactive"},
			},
			{
				name:          "migrate-clean-bare directory directive",
				args:          []string{"migrate-clean-bare", "--dry-run", ""},
				wantDirective: completionDirectiveDir,
			},
			{
				name:          "init-clean-bare directory directive",
				args:          []string{"init-clean-bare", ""},
				wantDirective: completionDirectiveDir,
			},
			{
				name:          "init-clean-bare stops dir directive on second positional arg",
				args:          []string{"init-clean-bare", "/tmp", ""},
				wantDirective: completionDirectiveNone,
			},
			{
				name:          "get flags",
				args:          []string{"get", "--"},
				wantDirective: completionDirectiveNone,
				wantAll:       []string{"--trust"},
			},
			{
				name:          "repo-fzf flags",
				args:          []string{"repo-fzf", "--"},
				wantDirective: completionDirectiveNone,
				wantAll:       []string{"--list"},
			},
			{
				name:          "log-fzf flags",
				args:          []string{"log-fzf", "--"},
				wantDirective: completionDirectiveNone,
				wantAll:       []string{"--ja"},
			},
			{
				name:          "completion shell values",
				args:          []string{"completion", ""},
				wantDirective: completionDirectiveNone,
				wantAll:       []string{"bash", "zsh"},
			},
			{
				name:          "hooks pre-push subcommands",
				args:          []string{"hooks", "pre-push", ""},
				wantDirective: completionDirectiveNone,
				wantAll:       []string{"betterleaks", "typos-commits", "typos-branch"},
			},
			{
				name:          "double dash stops flag completion",
				args:          []string{"show", "--", "--"},
				wantDirective: completionDirectiveNone,
				wantAbsent:    []string{"--ja", "--help"},
			},
		}

		for _, tc := range cases {
			t.Run(tc.name, func(t *testing.T) {
				res := completeArgs(tree, tc.args)
				if res.directive != tc.wantDirective {
					t.Errorf("directive = %q, want %q", res.directive, tc.wantDirective)
				}
				got := completionValues(res)
				for _, want := range tc.wantAll {
					if !slices.Contains(got, want) {
						t.Errorf("expected %q in %v", want, got)
					}
				}
				for _, absent := range tc.wantAbsent {
					if slices.Contains(got, absent) {
						t.Errorf("unexpected %q in %v", absent, got)
					}
				}
			})
		}
	})
}

func TestRunCompleteOutputProtocol(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if err := runGitX([]string{"__complete", "wt", ""}, strings.NewReader(""), &stdout, &stderr); err != nil {
		t.Fatalf("runGitX(__complete wt) failed: %v", err)
	}
	if stderr.Len() != 0 {
		t.Fatalf("expected empty stderr, got: %s", stderr.String())
	}

	lines := strings.Split(strings.TrimSuffix(stdout.String(), "\n"), "\n")
	if len(lines) < 2 {
		t.Fatalf("expected directive line plus candidates, got: %q", stdout.String())
	}
	if lines[0] != string(completionDirectiveNone) {
		t.Fatalf("expected first line %q, got %q", completionDirectiveNone, lines[0])
	}
	if !slices.ContainsFunc(lines[1:], func(line string) bool {
		return strings.HasPrefix(line, "add\t")
	}) {
		t.Fatalf("expected tab-delimited candidate line for add, got: %v", lines[1:])
	}
}

func TestBashCompletionBehavior(t *testing.T) {
	syntaxCmd := exec.Command("bash", "-n")
	syntaxCmd.Stdin = strings.NewReader(bashCompletionScript)
	if out, err := syntaxCmd.CombinedOutput(); err != nil {
		t.Fatalf("bash -n failed: %v\n%s", err, string(out))
	}

	binDir := t.TempDir()
	binPath := filepath.Join(binDir, "git-x")
	buildCmd := exec.Command("go", "build", "-o", binPath, ".")
	if out, err := buildCmd.CombinedOutput(); err != nil {
		t.Fatalf("go build git-x failed: %v\n%s", err, string(out))
	}

	cases := []struct {
		name      string
		words     string
		cword     int
		gitCmdIdx int
		wantAll   []string
		wantNone  []string
	}{
		{
			name:     "top-level subcommands",
			words:    `("` + binPath + `" "")`,
			cword:    1,
			wantAll:  []string{"menu", "wt", "get", "hooks", "completion", "help"},
			wantNone: []string{"_cd-helper", "__complete"},
		},
		{
			name:      "git x top-level subcommands",
			words:     `("git" "x" "")`,
			cword:     2,
			gitCmdIdx: 1,
			wantAll:   []string{"menu", "wt", "get", "hooks", "completion", "help"},
			wantNone:  []string{"_cd-helper", "__complete"},
		},
		{
			name:      "git -C repo x wt add flags",
			words:     `("git" "-C" "repo" "x" "wt" "add" "--")`,
			cword:     6,
			gitCmdIdx: 3,
			wantAll:   []string{"--branch", "--base", "--trust", "--interactive", "--help"},
		},
		{
			name:    "wt subcommands",
			words:   `("` + binPath + `" "wt" "")`,
			cword:   2,
			wantAll: []string{"list", "select", "add", "path", "help"},
		},
		{
			name:    "wt add flags",
			words:   `("` + binPath + `" "wt" "add" "--")`,
			cword:   3,
			wantAll: []string{"--branch", "--base", "--trust", "--interactive", "--help"},
		},
		{
			name:    "menu --mode values",
			words:   `("` + binPath + `" "menu" "--mode" "")`,
			cword:   3,
			wantAll: []string{"worktrees", "branches", "commits", "tags", "repos"},
		},
		{
			name:    "menu --mode= prefix values",
			words:   `("` + binPath + `" "menu" "--mode=w")`,
			cword:   2,
			wantAll: []string{"--mode=worktrees"},
		},
		{
			name:    "completion shell argument",
			words:   `("` + binPath + `" "completion" "")`,
			cword:   2,
			wantAll: []string{"bash", "zsh"},
		},
		{
			name:    "hooks pre-push subcommands",
			words:   `("` + binPath + `" "hooks" "pre-push" "")`,
			cword:   3,
			wantAll: []string{"betterleaks", "typos-commits", "typos-branch"},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			var setup string
			if tc.gitCmdIdx > 0 {
				setup = "PATH=" + strconv.Quote(binDir) + ":\"$PATH\"\n" +
					"words=" + tc.words + "\n" +
					"cword=" + strconv.Itoa(tc.cword) + "\n" +
					"__git_cmd_idx=" + strconv.Itoa(tc.gitCmdIdx) + "\n"
			} else {
				setup = "COMP_WORDS=" + tc.words + "\n" +
					"COMP_CWORD=" + strconv.Itoa(tc.cword) + "\n"
			}

			driver := bashCompletionScript + "\n" +
				setup +
				"_git_x\n" +
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

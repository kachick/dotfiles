package main

import (
	"bytes"
	"io"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
	"testing"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

func TestRunMenu_ModeSwitchingAndActions(t *testing.T) {
	t.Run("defaults to worktrees inside a git repo and switches across branches, commits, tags, and repos", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/remote-branch"}, "")
		runGit(t, defaultWT, "config", "user.name", "Tester")
		runGit(t, defaultWT, "config", "user.email", "tester@example.com")
		runGit(t, defaultWT, "branch", "feat/local-branch")
		runGit(t, defaultWT, "tag", "-a", "v1.0.0", "-m", "Release v1.0.0")

		var visitedModes []menuMode
		var shownRev string
		ui := menuInteractiveUI{
			selectMenuItem: func(mode menuMode, _ []string, input io.Reader, _ io.Writer) (selectChoice, error) {
				visitedModes = append(visitedModes, mode)
				rawInput, _ := io.ReadAll(input)
				text := string(rawInput)
				switch mode {
				case menuModeWorktrees:
					if !strings.Contains(text, defaultWT) {
						t.Errorf("worktrees input missing defaultWT %q:\n%s", defaultWT, text)
					}
					return selectChoice{Key: "ctrl-b"}, nil
				case menuModeBranches:
					if !strings.Contains(text, "feat/local-branch") || !strings.Contains(text, "origin/feat/remote-branch") {
						t.Errorf("branches input missing local or remote branch:\n%s", text)
					}
					return selectChoice{Key: "ctrl-l"}, nil
				case menuModeCommits:
					if !strings.Contains(text, "Initial commit") {
						t.Errorf("commits input missing Initial commit:\n%s", text)
					}
					return selectChoice{Key: "ctrl-t"}, nil
				case menuModeTags:
					if !strings.Contains(text, "v1.0.0") {
						t.Errorf("tags input missing v1.0.0:\n%s", text)
					}
					return selectChoice{Key: "", Path: "v1.0.0"}, nil
				default:
					t.Fatalf("unexpected mode %q", mode)
					return selectChoice{}, nil
				}
			},
			showRevDetail: func(_, rev string, _ io.Writer) error {
				shownRev = rev
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runMenuWithUI(nil, defaultWT, ui, &stdout, &stderr); err != nil {
			t.Fatalf("runMenuWithUI failed: %v, stderr: %s", err, stderr.String())
		}

		wantModes := []menuMode{menuModeWorktrees, menuModeBranches, menuModeCommits, menuModeTags}
		if !slices.Equal(visitedModes, wantModes) {
			t.Errorf("visitedModes = %v, want %v", visitedModes, wantModes)
		}
		if shownRev != "v1.0.0" {
			t.Errorf("shownRev = %q, want v1.0.0", shownRev)
		}
		if stdout.Len() != 0 {
			t.Errorf("expected empty stdout for tag detail action, got %q", stdout.String())
		}
		_ = repoDir
	})

	t.Run("defaults to repos mode outside a git repository and prints selected repo path", func(t *testing.T) {
		isolateEnv(t)
		repoRoot := t.TempDir()
		t.Setenv("GIT_X_ROOT", repoRoot)
		targetRepo := createRepoCleanBareRepo(t, repoRoot, "github.com/kachick/dotfiles", "main")
		wantWT := filepath.Join(targetRepo, "main")

		outsideDir := t.TempDir()
		var gotMode menuMode
		ui := menuInteractiveUI{
			selectMenuItem: func(mode menuMode, _ []string, input io.Reader, _ io.Writer) (selectChoice, error) {
				gotMode = mode
				raw, _ := io.ReadAll(input)
				if !strings.Contains(string(raw), wantWT) {
					t.Errorf("repos input missing %q:\n%s", wantWT, string(raw))
				}
				return selectChoice{Key: "", Path: wantWT}, nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runMenuWithUI(nil, outsideDir, ui, &stdout, &stderr); err != nil {
			t.Fatalf("runMenuWithUI outside repo failed: %v, stderr: %s", err, stderr.String())
		}
		if gotMode != menuModeRepos {
			t.Errorf("initial mode outside repo = %q, want %q", gotMode, menuModeRepos)
		}
		if got := strings.TrimSpace(stdout.String()); got != wantWT {
			t.Errorf("stdout = %q, want %q", got, wantWT)
		}
	})

	t.Run("branches mode creates or switches flat worktree in clean-bare repo on enter", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/remote-checkout"}, "")

		ui := menuInteractiveUI{
			selectMenuItem: func(mode menuMode, _ []string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				if mode != menuModeBranches {
					t.Fatalf("unexpected mode %q", mode)
				}
				return selectChoice{Key: "", Path: "origin/feat/remote-checkout"}, nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runMenuWithUI([]string{"--mode", "branches"}, defaultWT, ui, &stdout, &stderr); err != nil {
			t.Fatalf("branches mode checkout failed: %v, stderr: %s", err, stderr.String())
		}
		wantWT := filepath.Join(repoDir, "feat-remote-checkout")
		if got := strings.TrimSpace(stdout.String()); got != wantWT {
			t.Errorf("stdout = %q, want %q", got, wantWT)
		}
		if br := runGit(t, wantWT, "symbolic-ref", "--short", "HEAD"); br != "feat/remote-checkout" {
			t.Errorf("checked out branch = %q, want feat/remote-checkout", br)
		}
	})

	t.Run("branches mode runs git switch in standard non-bare repo on enter", func(t *testing.T) {
		isolateEnv(t)
		legacyDir := createRepoLegacyRepo(t, t.TempDir(), "github.com/kachick/legacy", "main")
		runGit(t, legacyDir, "branch", "feat/legacy-topic")

		ui := menuInteractiveUI{
			selectMenuItem: func(_ menuMode, _ []string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "", Path: "feat/legacy-topic"}, nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runMenuWithUI([]string{"--mode", "branches"}, legacyDir, ui, &stdout, &stderr); err != nil {
			t.Fatalf("branches mode in legacy repo failed: %v, stderr: %s", err, stderr.String())
		}
		if stdout.Len() != 0 {
			t.Errorf("expected empty stdout for legacy git switch, got %q", stdout.String())
		}
		if br := runGit(t, legacyDir, "symbolic-ref", "--short", "HEAD"); br != "feat/legacy-topic" {
			t.Errorf("checked out branch = %q, want feat/legacy-topic", br)
		}
	})

	t.Run("ctrl-x dispatches refresh and delete-merged-branches actions", func(t *testing.T) {
		isolateEnv(t)
		_, defaultWT := setupCleanBareRepo(t, "main", nil, "")

		var refreshCalled, deletePRCalled bool
		ui := menuInteractiveUI{
			selectMenuItem: func(_ menuMode, _ []string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-x", Path: defaultWT}, nil
			},
			chooseAction: func(_ string, options []string, _ io.Writer) (string, error) {
				if !slices.Contains(options, menuActionRefresh) || !slices.Contains(options, menuActionDeleteMergedWithPR) {
					t.Errorf("expected maintenance actions in options, got %v", options)
				}
				return menuActionRefresh, nil
			},
			runRefresh: func(workDir string, _ io.Writer) error {
				if workDir != defaultWT {
					t.Errorf("runRefresh workDir = %q, want %q", workDir, defaultWT)
				}
				refreshCalled = true
				return nil
			},
			runDeleteMerged: func(pr bool, _ string, _ io.Writer) error {
				deletePRCalled = pr
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runMenuWithUI(nil, defaultWT, ui, &stdout, &stderr); err != nil {
			t.Fatalf("ctrl-x refresh failed: %v, stderr: %s", err, stderr.String())
		}
		if !refreshCalled {
			t.Errorf("expected runRefresh to be called")
		}

		ui.chooseAction = func(_ string, _ []string, _ io.Writer) (string, error) {
			return menuActionDeleteMergedWithPR, nil
		}
		if err := runMenuWithUI([]string{"--mode", "branches"}, defaultWT, ui, &stdout, &stderr); err != nil {
			t.Fatalf("ctrl-x delete-merged-branches --pr failed: %v, stderr: %s", err, stderr.String())
		}
		if !deletePRCalled {
			t.Errorf("expected runDeleteMerged(true) to be called")
		}
	})

	t.Run("renders branch and tag previews and filters with fzf", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/remote-preview"}, "")
		runGit(t, defaultWT, "tag", "v0.1.0")

		var previewOut, stderr bytes.Buffer
		if err := runMenu([]string{"_preview-branch", repoDir, "main", "origin/feat/remote-preview"}, repoDir, &previewOut, &stderr); err != nil {
			t.Fatalf("_preview-branch failed: %v, stderr: %s", err, stderr.String())
		}
		for _, want := range []string{"Branch:   origin/feat/remote-preview", "Commit on feat/remote-preview"} {
			if !strings.Contains(previewOut.String(), want) {
				t.Errorf("branch preview missing %q:\n%s", want, previewOut.String())
			}
		}

		previewOut.Reset()
		if err := runMenu([]string{"_preview-tag", "v0.1.0"}, defaultWT, &previewOut, &stderr); err != nil {
			t.Fatalf("_preview-tag failed: %v, stderr: %s", err, stderr.String())
		}
		if !strings.Contains(previewOut.String(), "Initial commit") {
			t.Errorf("tag preview missing Initial commit:\n%s", previewOut.String())
		}

		r := gitcmd.NewIsolated(repoDir, &stderr, &stderr)
		branches, err := collectMenuBranches(r, "main", "main")
		if err != nil {
			t.Fatalf("collectMenuBranches failed: %v", err)
		}
		var brInput strings.Builder
		for _, b := range branches {
			brInput.WriteString(formatMenuBranchLine(b))
			brInput.WriteByte('\n')
		}

		filterArgs := append([]string{"--filter=remote-preview"}, menuBranchFzfArgs("git-x", repoDir, "main", "")...)
		fzfCmd := exec.Command("fzf", filterArgs...)
		fzfCmd.Stdin = strings.NewReader(brInput.String())
		fzfOut, err := fzfCmd.Output()
		if err != nil {
			t.Fatalf("fzf --filter on branches failed: %v", err)
		}
		lines := strings.Split(strings.TrimSpace(string(fzfOut)), "\n")
		if len(lines) != 2 || lines[1] != "origin/feat/remote-preview" {
			t.Errorf("fzf branch filter output = %q, want [remote-preview origin/feat/remote-preview]", lines)
		}
	})
}

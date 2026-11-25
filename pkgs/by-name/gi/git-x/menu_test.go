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
	t.Run("defaults to commits inside a worktree, worktrees at bare repo root, and switches views", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/remote-branch"}, "")
		runGit(t, defaultWT, "config", "user.name", "Tester")
		runGit(t, defaultWT, "config", "user.email", "tester@example.com")
		runGit(t, defaultWT, "branch", "feat/local-branch")
		runGit(t, defaultWT, "tag", "-a", "v1.0.0", "-m", "Release v1.0.0")

		// Inside a worktree, auto mode opens commits first.
		var visitedModes []menuMode
		var shownRev string
		ui := menuInteractiveUI{
			selectMenuItem: func(mode menuMode, _ []string, input io.Reader, _ io.Writer) (selectChoice, error) {
				visitedModes = append(visitedModes, mode)
				rawInput, _ := io.ReadAll(input)
				text := string(rawInput)
				switch mode {
				case menuModeCommits:
					if !strings.Contains(text, "Initial commit") {
						t.Errorf("commits input missing Initial commit:\n%s", text)
					}
					return selectChoice{Key: "ctrl-w"}, nil
				case menuModeWorktrees:
					if !strings.Contains(text, defaultWT) {
						t.Errorf("worktrees input missing defaultWT %q:\n%s", defaultWT, text)
					}
					return selectChoice{Key: "ctrl-b"}, nil
				case menuModeBranches:
					if !strings.Contains(text, "feat/local-branch") || !strings.Contains(text, "origin/feat/remote-branch") {
						t.Errorf("branches input missing local or remote branch:\n%s", text)
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

		wantModes := []menuMode{menuModeCommits, menuModeWorktrees, menuModeBranches, menuModeTags}
		if !slices.Equal(visitedModes, wantModes) {
			t.Errorf("visitedModes = %v, want %v", visitedModes, wantModes)
		}
		if shownRev != "v1.0.0" {
			t.Errorf("shownRev = %q, want v1.0.0", shownRev)
		}
		if stdout.Len() != 0 {
			t.Errorf("expected empty stdout for tag detail action, got %q", stdout.String())
		}

		// At the clean-bare container root (outside any worktree), auto mode opens worktrees first.
		var rootInitialMode menuMode
		rootUI := menuInteractiveUI{
			selectMenuItem: func(mode menuMode, _ []string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				rootInitialMode = mode
				return selectChoice{Key: "", Path: defaultWT}, nil
			},
		}
		stdout.Reset()
		stderr.Reset()
		if err := runMenuWithUI(nil, repoDir, rootUI, &stdout, &stderr); err != nil {
			t.Fatalf("runMenuWithUI at bare root failed: %v, stderr: %s", err, stderr.String())
		}
		if rootInitialMode != menuModeWorktrees {
			t.Errorf("initial mode at bare repo root = %q, want %q", rootInitialMode, menuModeWorktrees)
		}
		if got := strings.TrimSpace(stdout.String()); got != defaultWT {
			t.Errorf("stdout at bare repo root = %q, want %q", got, defaultWT)
		}
	})

	t.Run("worktrees ctrl-l switches to commits view for the selected worktree", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", []string{"feat/other-log"}, "")
		var addOut, addErr bytes.Buffer
		if err := runWT([]string{"add", "--branch", "feat/other-log"}, defaultWT, &addOut, &addErr); err != nil {
			t.Fatalf("wt add feat/other-log failed: %v, stderr: %s", err, addErr.String())
		}
		otherWT := filepath.Join(repoDir, "feat-other-log")

		var gotCommitDir string
		var gotCommitLog string
		ui := menuInteractiveUI{
			selectMenuItem: func(mode menuMode, _ []string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				if mode != menuModeWorktrees {
					t.Fatalf("unexpected mode %q", mode)
				}
				return selectChoice{Key: "ctrl-l", Path: otherWT}, nil
			},
			selectCommitItem: func(gitDir string, _ []string, stderr io.Writer) (selectChoice, error) {
				gotCommitDir = gitDir
				r := gitcmd.New(gitDir, stderr, stderr)
				raw, err := r.OutputRaw("log", "--format="+defaultLogFormat, "--date=short", "--color=always")
				if err != nil {
					return selectChoice{}, err
				}
				gotCommitLog = string(raw)
				return selectChoice{}, gitcmd.ErrSelectionCanceled
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runMenuWithUI([]string{"--mode", "worktrees"}, defaultWT, ui, &stdout, &stderr); err != nil {
			t.Fatalf("worktrees ctrl-l failed: %v, stderr: %s", err, stderr.String())
		}
		if gotCommitDir != otherWT {
			t.Errorf("commits view gitDir = %q, want %q", gotCommitDir, otherWT)
		}
		if !strings.Contains(gotCommitLog, "Commit on feat/other-log") {
			t.Errorf("expected commits log from selected worktree, got:\n%s", gotCommitLog)
		}
	})

	t.Run("worktrees ctrl-a, ctrl-d guards, ctrl-x pr and promote, and repos ctrl-a clone", func(t *testing.T) {
		isolateEnv(t)
		repoDir, defaultWT := setupCleanBareRepo(t, "main", nil, "")

		// Worktrees ctrl-d refuses to remove current or default worktree.
		var stdout, stderr bytes.Buffer
		removeDefaultUI := menuInteractiveUI{
			selectMenuItem: func(_ menuMode, _ []string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-d", Path: defaultWT}, nil
			},
			wtUI: wtInteractiveUI{
				confirmRemoveWorktree: func(_, _ string, _ io.Writer) (bool, error) {
					t.Fatal("confirmRemoveWorktree should not be called for default worktree")
					return false, nil
				},
			},
		}
		if err := runMenuWithUI([]string{"--mode", "worktrees"}, defaultWT, removeDefaultUI, &stdout, &stderr); err == nil {
			t.Fatal("expected error when removing default worktree")
		}

		// Worktrees ctrl-x -> PR checkout.
		var gotPRSpec string
		prUI := menuInteractiveUI{
			selectMenuItem: func(_ menuMode, _ []string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-x", Path: defaultWT}, nil
			},
			chooseAction: func(_ string, options []string, _ io.Writer) (string, error) {
				if !slices.Contains(options, menuActionWTPR) || !slices.Contains(options, menuActionWTPromote) {
					t.Errorf("expected PR and promote actions in options, got %v", options)
				}
				return menuActionWTPR, nil
			},
			inputText: func(_, _ string, _ io.Writer) (string, error) {
				return "42", nil
			},
			runWTPR: func(spec, _ string, stdout, _ io.Writer) error {
				gotPRSpec = spec
				stdout.Write([]byte(filepath.Join(repoDir, "pr-42") + "\n"))
				return nil
			},
		}
		stdout.Reset()
		stderr.Reset()
		if err := runMenuWithUI([]string{"--mode", "worktrees"}, defaultWT, prUI, &stdout, &stderr); err != nil {
			t.Fatalf("worktrees ctrl-x pr failed: %v, stderr: %s", err, stderr.String())
		}
		if gotPRSpec != "42" || strings.TrimSpace(stdout.String()) != filepath.Join(repoDir, "pr-42") {
			t.Errorf("gotPRSpec=%q stdout=%q", gotPRSpec, stdout.String())
		}

		// Worktrees ctrl-x -> promote.
		var promoteCalled bool
		promoteUI := menuInteractiveUI{
			selectMenuItem: func(_ menuMode, _ []string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-x", Path: defaultWT}, nil
			},
			chooseAction: func(_ string, _ []string, _ io.Writer) (string, error) {
				return menuActionWTPromote, nil
			},
			runWTPromote: func(wd string, stdout, _ io.Writer) error {
				promoteCalled = wd == defaultWT
				stdout.Write([]byte(filepath.Join(repoDir, "promoted") + "\n"))
				return nil
			},
		}
		stdout.Reset()
		stderr.Reset()
		if err := runMenuWithUI([]string{"--mode", "worktrees"}, defaultWT, promoteUI, &stdout, &stderr); err != nil {
			t.Fatalf("worktrees ctrl-x promote failed: %v, stderr: %s", err, stderr.String())
		}
		if !promoteCalled || strings.TrimSpace(stdout.String()) != filepath.Join(repoDir, "promoted") {
			t.Errorf("promoteCalled=%v stdout=%q", promoteCalled, stdout.String())
		}

		// Repos ctrl-a -> clone via git x get.
		var clonedSpec string
		cloneUI := menuInteractiveUI{
			selectMenuItem: func(_ menuMode, _ []string, _ io.Reader, _ io.Writer) (selectChoice, error) {
				return selectChoice{Key: "ctrl-a"}, nil
			},
			inputText: func(_, _ string, _ io.Writer) (string, error) {
				return "kachick/dotfiles", nil
			},
			runRepoClone: func(spec string, stdout, _ io.Writer) error {
				clonedSpec = spec
				stdout.Write([]byte("/repos/github.com/kachick/dotfiles/main\n"))
				return nil
			},
		}
		stdout.Reset()
		stderr.Reset()
		if err := runMenuWithUI([]string{"--mode", "repos"}, t.TempDir(), cloneUI, &stdout, &stderr); err != nil {
			t.Fatalf("repos ctrl-a clone failed: %v, stderr: %s", err, stderr.String())
		}
		if clonedSpec != "kachick/dotfiles" || strings.TrimSpace(stdout.String()) != "/repos/github.com/kachick/dotfiles/main" {
			t.Errorf("clonedSpec=%q stdout=%q", clonedSpec, stdout.String())
		}
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

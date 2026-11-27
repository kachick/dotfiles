package main

import (
	"bytes"
	"errors"
	"os"
	"os/exec"
	"slices"
	"strings"
	"testing"
	"time"

	"github.com/kachick/dotfiles/pkgs/by-name/gi/git-x/internal/gitcmd"
)

func TestLocaleDefaultsToJa(t *testing.T) {
	cases := []struct {
		name       string
		lcAll      string
		lcMessages string
		lang       string
		want       bool
	}{
		{name: "ja_JP.UTF-8 via LANG", lang: "ja_JP.UTF-8", want: true},
		{name: "ja via LANG", lang: "ja", want: true},
		{name: "ja-JP via LANG", lang: "ja-JP", want: true},
		{name: "LC_ALL=C overrides LANG=ja_JP.UTF-8", lcAll: "C", lang: "ja_JP.UTF-8", want: false},
		{name: "LC_MESSAGES=en_US.UTF-8 overrides LANG=ja_JP.UTF-8", lcMessages: "en_US.UTF-8", lang: "ja_JP.UTF-8", want: false},
		{name: "LC_ALL=ja_JP.UTF-8 overrides LANG=C", lcAll: "ja_JP.UTF-8", lang: "C", want: true},
		{name: "LC_MESSAGES=ja_JP.UTF-8 overrides LANG=C", lcMessages: "ja_JP.UTF-8", lang: "C", want: true},
		{name: "LANG=C", lang: "C", want: false},
		{name: "all empty", want: false},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("LC_ALL", tc.lcAll)
			t.Setenv("LC_MESSAGES", tc.lcMessages)
			t.Setenv("LANG", tc.lang)
			if got := localeDefaultsToJa(); got != tc.want {
				t.Errorf("localeDefaultsToJa() = %v, want %v", got, tc.want)
			}
		})
	}
}

func TestCleanRev(t *testing.T) {
	tests := []struct {
		name string
		raw  string
		want string
	}{
		{
			name: "empty input",
			raw:  "",
			want: "",
		},
		{
			name: "git log full line",
			raw:  "2026-11-07 c38fc2ba Migrate git-log-fzf-ja to Go  (HEAD -> main)",
			want: "c38fc2ba",
		},
		{
			name: "single field token from fzf {2}",
			raw:  "c38fc2ba",
			want: "c38fc2ba",
		},
		{
			name: "single token with ansi escapes from fzf {2}",
			raw:  "\x1b[33mc38fc2ba\x1b[0m",
			want: "c38fc2ba",
		},
		{
			name: "full line with ansi escapes",
			raw:  "\x1b[36m2026-11-07\x1b[0m \x1b[33mc38fc2ba\x1b[0m \x1b[32mMigrate git-log-fzf-ja\x1b[0m",
			want: "c38fc2ba",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := cleanRev(tt.raw)
			if got != tt.want {
				t.Errorf("cleanRev(%q) = %q, want %q", tt.raw, got, tt.want)
			}
		})
	}
}

func TestNeighborRevs(t *testing.T) {
	commits := []string{"c0", "c1", "c2", "c3", "c4"}
	idxMap := map[string]int{
		"c0": 0,
		"c1": 1,
		"c2": 2,
		"c3": 3,
		"c4": 4,
	}

	tests := []struct {
		name string
		rev  string
		want []string
	}{
		{
			name: "first commit in log",
			rev:  "c0",
			want: []string{"c1", "c2"},
		},
		{
			name: "middle commit in log",
			rev:  "c2",
			want: []string{"c3", "c1", "c4"},
		},
		{
			name: "last commit in log",
			rev:  "c4",
			want: []string{"c3"},
		},
		{
			name: "unknown commit",
			rev:  "unknown",
			want: nil,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := neighborRevs(commits, idxMap, tt.rev)
			if !slices.Equal(got, tt.want) {
				t.Errorf("neighborRevs(%q) = %v, want %v", tt.rev, got, tt.want)
			}
		})
	}
}

func TestMenuCommitFzfArgs(t *testing.T) {
	jaArgs := strings.Join(menuCommitFzfArgs("/bin/git-x", "/repo/wt", "/tmp/cache", "/tmp/cache/fzf.sock", "fix typo", true), "\n")
	wantPreview := `--preview='/bin/git-x' menu _preview-commit '/repo/wt' '/tmp/cache' {2}`
	wantToggle := `--bind=alt-j:transform('/bin/git-x' menu _toggle-ja '/tmp/cache')`
	wantZoom := `--bind=alt-f:change-preview-window(down,80%|)`
	if !strings.Contains(jaArgs, "--border-label=🪵 Commits (ja) (Ctrl-G)") ||
		!strings.Contains(jaArgs, "--listen=/tmp/cache/fzf.sock") ||
		!strings.Contains(jaArgs, wantPreview) ||
		!strings.Contains(jaArgs, wantToggle) ||
		!strings.Contains(jaArgs, wantZoom) ||
		!strings.Contains(jaArgs, "--query\nfix typo") {
		t.Errorf("unexpected ja menu commit fzf args:\n%s", jaArgs)
	}

	plainArgs := strings.Join(menuCommitFzfArgs("/bin/git-x", "/repo/wt", "/tmp/cache", "/tmp/cache/fzf.sock", "", false), "\n")
	if !strings.Contains(plainArgs, "--border-label=🪵 Commits (Ctrl-G)") ||
		strings.Contains(plainArgs, "Commits (ja)") ||
		!strings.Contains(plainArgs, wantPreview) ||
		!strings.Contains(plainArgs, wantToggle) ||
		!strings.Contains(plainArgs, wantZoom) {
		t.Errorf("unexpected plain menu commit fzf args:\n%s", plainArgs)
	}
}

func TestMenuToggleJa(t *testing.T) {
	cacheDir := t.TempDir()

	if isJaEnabled(cacheDir) {
		t.Fatal("expected ja mode to start disabled")
	}

	var out bytes.Buffer
	var stderr bytes.Buffer
	if err := runMenu([]string{"_toggle-ja", cacheDir}, "", &out, &stderr); err != nil {
		t.Fatalf("first _toggle-ja failed: %v", err)
	}
	if !isJaEnabled(cacheDir) {
		t.Fatal("expected ja mode to be enabled after first toggle")
	}
	if got, want := out.String(), "change-border-label(🪵 Commits (ja) (Ctrl-G))+refresh-preview\n"; got != want {
		t.Errorf("first _toggle-ja output = %q, want %q", got, want)
	}

	out.Reset()
	if err := runMenu([]string{"_toggle-ja", cacheDir}, "", &out, &stderr); err != nil {
		t.Fatalf("second _toggle-ja failed: %v", err)
	}
	if isJaEnabled(cacheDir) {
		t.Fatal("expected ja mode to be disabled after second toggle")
	}
	if got, want := out.String(), "change-border-label(🪵 Commits (Ctrl-G))+refresh-preview\n"; got != want {
		t.Errorf("second _toggle-ja output = %q, want %q", got, want)
	}
}

func TestMenuCommitPreviewEmpty(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if err := runMenu([]string{"_preview-commit", "", t.TempDir(), ""}, "", &stdout, &stderr); err != nil {
		t.Fatalf("runMenu(_preview-commit, empty) failed: %v", err)
	}
	if stdout.Len() != 0 || stderr.Len() != 0 {
		t.Errorf("expected empty output, got stdout=%q stderr=%q", stdout.String(), stderr.String())
	}
}

func TestMenuCommitPipelineHelperProcess(t *testing.T) {
	mode := os.Getenv("GIT_X_TEST_PIPE_MODE")
	if mode == "" {
		return
	}
	switch mode {
	case "producer-large":
		// Write far more than the typical 64KB OS pipe buffer so an unclosed read end blocks.
		chunk := bytes.Repeat([]byte("a"), 16*1024)
		for range 64 {
			if _, err := os.Stdout.Write(chunk); err != nil {
				os.Exit(0)
			}
		}
		os.Exit(0)
	case "consumer-cancel":
		os.Exit(130)
	case "consumer-fail":
		os.Exit(2)
	default:
		os.Exit(99)
	}
}

func helperPipeCommand(t *testing.T, mode string) *exec.Cmd {
	t.Helper()
	exe, err := os.Executable()
	if err != nil {
		t.Fatalf("os.Executable: %v", err)
	}
	cmd := exec.Command(exe, "-test.run=^TestMenuCommitPipelineHelperProcess$")
	cmd.Env = append(os.Environ(), "GIT_X_TEST_PIPE_MODE="+mode)
	return cmd
}

func TestRunMenuCommitPipelineEarlyCancel(t *testing.T) {
	producer := helperPipeCommand(t, "producer-large")
	consumer := helperPipeCommand(t, "consumer-cancel")

	done := make(chan error, 1)
	go func() {
		_, err := runMenuCommitPipeline(producer, consumer)
		done <- err
	}()

	select {
	case err := <-done:
		if !errors.Is(err, gitcmd.ErrSelectionCanceled) {
			t.Fatalf("runMenuCommitPipeline() err = %v, want ErrSelectionCanceled", err)
		}
	case <-time.After(2 * time.Second):
		if producer.Process != nil {
			_ = producer.Process.Kill()
		}
		if consumer.Process != nil {
			_ = consumer.Process.Kill()
		}
		t.Fatal("runMenuCommitPipeline() deadlocked after consumer exited early")
	}
}

func TestRunMenuCommitPipelineConsumerError(t *testing.T) {
	producer := helperPipeCommand(t, "producer-large")
	consumer := helperPipeCommand(t, "consumer-fail")

	done := make(chan error, 1)
	go func() {
		_, err := runMenuCommitPipeline(producer, consumer)
		done <- err
	}()

	select {
	case err := <-done:
		if err == nil || errors.Is(err, gitcmd.ErrSelectionCanceled) {
			t.Fatalf("runMenuCommitPipeline() err = %v, want non-cancel error", err)
		}
	case <-time.After(2 * time.Second):
		if producer.Process != nil {
			_ = producer.Process.Kill()
		}
		if consumer.Process != nil {
			_ = consumer.Process.Kill()
		}
		t.Fatal("runMenuCommitPipeline() deadlocked after consumer failed")
	}
}

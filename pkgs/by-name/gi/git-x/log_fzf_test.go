package main

import (
	"bytes"
	"os"
	"os/exec"
	"slices"
	"strings"
	"testing"
	"time"
)

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

func TestParseAndBuildLogFzfArgs(t *testing.T) {
	opts, err := parseLogFzfArgs([]string{"--ja", "fix typo"})
	if err != nil {
		t.Fatalf("parseLogFzfArgs failed: %v", err)
	}
	if !opts.ja || opts.query != "fix typo" {
		t.Errorf("unexpected opts: %+v", opts)
	}

	jaArgs := strings.Join(buildLogFzfArgs("/bin/git-x", "/tmp/cache", "/tmp/cache/fzf.sock", opts), "\n")
	wantPreviewSubcmd := `"/bin/git-x" log-fzf _preview "/tmp/cache" {2}`
	wantToggleBind := `alt-j:transform("/bin/git-x" log-fzf _toggle-ja "/tmp/cache")`
	wantZoomBind := "alt-f:change-preview-window(down,80%|)"
	if !strings.Contains(jaArgs, "--border-label\n🪵 Logs (ja)") ||
		!strings.Contains(jaArgs, "--listen=/tmp/cache/fzf.sock") ||
		!strings.Contains(jaArgs, "--preview\n"+wantPreviewSubcmd) ||
		!strings.Contains(jaArgs, wantToggleBind) ||
		!strings.Contains(jaArgs, wantZoomBind) ||
		strings.Contains(jaArgs, "enter:") {
		t.Errorf("unexpected ja fzf args:\n%s", jaArgs)
	}

	plainOpts, err := parseLogFzfArgs([]string{"feat"})
	if err != nil {
		t.Fatalf("parseLogFzfArgs plain failed: %v", err)
	}
	plainArgs := strings.Join(buildLogFzfArgs("/bin/git-x", "/tmp/cache", "/tmp/cache/fzf.sock", plainOpts), "\n")
	if !strings.Contains(plainArgs, "--border-label\n🪵 Logs\n") ||
		strings.Contains(plainArgs, "🪵 Logs (ja)") ||
		!strings.Contains(plainArgs, "--listen=/tmp/cache/fzf.sock") ||
		!strings.Contains(plainArgs, "--query\nfeat") ||
		!strings.Contains(plainArgs, "--preview\n"+wantPreviewSubcmd) ||
		!strings.Contains(plainArgs, wantToggleBind) ||
		!strings.Contains(plainArgs, wantZoomBind) ||
		strings.Contains(plainArgs, "enter:") ||
		strings.Contains(plainArgs, "--height") ||
		strings.Contains(plainArgs, "--tmux") ||
		strings.Contains(plainArgs, "ansi2txt") ||
		strings.Contains(plainArgs, "xargs") {
		t.Errorf("unexpected plain fzf args:\n%s", plainArgs)
	}
}

func TestLogFzfToggleJa(t *testing.T) {
	cacheDir := t.TempDir()

	if isJaEnabled(cacheDir) {
		t.Fatal("expected ja mode to start disabled")
	}

	var out bytes.Buffer
	var stderr bytes.Buffer
	if err := runLogFzf([]string{"_toggle-ja", cacheDir}, strings.NewReader(""), &out, &stderr); err != nil {
		t.Fatalf("first _toggle-ja failed: %v", err)
	}
	if !isJaEnabled(cacheDir) {
		t.Fatal("expected ja mode to be enabled after first toggle")
	}
	if got, want := out.String(), "change-border-label(🪵 Logs (ja))+refresh-preview\n"; got != want {
		t.Errorf("first _toggle-ja output = %q, want %q", got, want)
	}

	out.Reset()
	if err := runLogFzf([]string{"_toggle-ja", cacheDir}, strings.NewReader(""), &out, &stderr); err != nil {
		t.Fatalf("second _toggle-ja failed: %v", err)
	}
	if isJaEnabled(cacheDir) {
		t.Fatal("expected ja mode to be disabled after second toggle")
	}
	if got, want := out.String(), "change-border-label(🪵 Logs)+refresh-preview\n"; got != want {
		t.Errorf("second _toggle-ja output = %q, want %q", got, want)
	}
}

func TestRunLogFzfPreviewPlainEmpty(t *testing.T) {
	var stdout, stderr bytes.Buffer
	if err := runLogFzf([]string{"_preview-plain", ""}, strings.NewReader(""), &stdout, &stderr); err != nil {
		t.Fatalf("runLogFzf(_preview-plain, empty) failed: %v", err)
	}
	if stdout.Len() != 0 || stderr.Len() != 0 {
		t.Errorf("expected empty output, got stdout=%q stderr=%q", stdout.String(), stderr.String())
	}
}

func TestLogFzfPipelineHelperProcess(t *testing.T) {
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
	cmd := exec.Command(exe, "-test.run=^TestLogFzfPipelineHelperProcess$")
	cmd.Env = append(os.Environ(), "GIT_X_TEST_PIPE_MODE="+mode)
	return cmd
}

func TestRunLogFzfPipelineEarlyCancel(t *testing.T) {
	producer := helperPipeCommand(t, "producer-large")
	consumer := helperPipeCommand(t, "consumer-cancel")

	done := make(chan error, 1)
	go func() {
		done <- runLogFzfPipeline(producer, consumer)
	}()

	select {
	case err := <-done:
		if err != nil {
			t.Fatalf("runLogFzfPipeline() returned unexpected error: %v", err)
		}
	case <-time.After(2 * time.Second):
		if producer.Process != nil {
			_ = producer.Process.Kill()
		}
		if consumer.Process != nil {
			_ = consumer.Process.Kill()
		}
		t.Fatal("runLogFzfPipeline() deadlocked after consumer exited early")
	}
}

func TestRunLogFzfPipelineConsumerError(t *testing.T) {
	producer := helperPipeCommand(t, "producer-large")
	consumer := helperPipeCommand(t, "consumer-fail")

	done := make(chan error, 1)
	go func() {
		done <- runLogFzfPipeline(producer, consumer)
	}()

	select {
	case err := <-done:
		if err == nil {
			t.Fatal("runLogFzfPipeline() returned nil, want non-zero consumer error")
		}
	case <-time.After(2 * time.Second):
		if producer.Process != nil {
			_ = producer.Process.Kill()
		}
		if consumer.Process != nil {
			_ = consumer.Process.Kill()
		}
		t.Fatal("runLogFzfPipeline() deadlocked after consumer failed")
	}
}

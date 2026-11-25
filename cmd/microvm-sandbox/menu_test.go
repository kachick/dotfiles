package main

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"slices"
	"strconv"
	"strings"
	"testing"
)

func TestParseMenuFzfOutput(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		raw  string
		want menuChoice
	}{
		{
			name: "empty",
			raw:  "",
			want: menuChoice{},
		},
		{
			name: "enter on selected instance",
			raw:  "alp\n\nalpha\n",
			want: menuChoice{Query: "alp", Key: "", Name: "alpha"},
		},
		{
			name: "ctrl-d on selected instance",
			raw:  "\nctrl-d\nwork-1\n",
			want: menuChoice{Query: "", Key: "ctrl-d", Name: "work-1"},
		},
		{
			name: "ctrl-a with no instances",
			raw:  "\nctrl-a\n",
			want: menuChoice{Query: "", Key: "ctrl-a", Name: ""},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			if got := parseMenuFzfOutput(tt.raw); got != tt.want {
				t.Errorf("parseMenuFzfOutput(%q) = %+v, want %+v", tt.raw, got, tt.want)
			}
		})
	}
}

func TestFormatMenuInstanceLine(t *testing.T) {
	t.Parallel()

	running := formatMenuInstanceLine(instanceInfo{name: "alpha", running: true, pid: 1234, port: 2221})
	name, display, ok := strings.Cut(running, "\t")
	if !ok || name != "alpha" {
		t.Fatalf("unexpected tab format: %q", running)
	}
	if !strings.Contains(display, "running") || !strings.Contains(display, "1234") || !strings.Contains(display, "2221") {
		t.Errorf("missing fields in running display: %q", display)
	}

	stopped := formatMenuInstanceLine(instanceInfo{name: "beta", running: false, port: 2222})
	name, display, ok = strings.Cut(stopped, "\t")
	if !ok || name != "beta" {
		t.Fatalf("unexpected tab format: %q", stopped)
	}
	if !strings.Contains(display, "stopped") || !strings.Contains(display, "-") || !strings.Contains(display, "2222") {
		t.Errorf("missing fields in stopped display: %q", display)
	}
}

func TestRenderInstancePreview(t *testing.T) {
	t.Parallel()

	t.Run("empty name writes nothing", func(t *testing.T) {
		t.Parallel()
		var buf bytes.Buffer
		if err := renderInstancePreview(t.TempDir(), "", &buf); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if buf.Len() != 0 {
			t.Errorf("expected empty output, got %q", buf.String())
		}
	})

	t.Run("shows metadata and console tail", func(t *testing.T) {
		t.Parallel()
		root := t.TempDir()
		stateDir := filepath.Join(root, "work-1")
		if err := os.MkdirAll(stateDir, 0o755); err != nil {
			t.Fatal(err)
		}

		pid := os.Getpid()
		if err := os.WriteFile(filepath.Join(stateDir, "qemu.pid"), []byte(strconv.Itoa(pid)+"\n"), 0o644); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(stateDir, "ssh.port"), []byte("2223\n"), 0o644); err != nil {
			t.Fatal(err)
		}
		patched, err := patchRunnerContent(sampleMicrovmRun, patchOptions{
			name:     "work-1",
			port:     2223,
			stateDir: stateDir,
			plain:    true,
			mountDir: "/tmp/my-worktree",
		})
		if err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(filepath.Join(stateDir, "microvm-run"), []byte(patched), 0o755); err != nil {
			t.Fatal(err)
		}

		var logLines []string
		for i := 1; i <= 50; i++ {
			logLines = append(logLines, fmt.Sprintf("boot line %d", i))
		}
		if err := os.WriteFile(filepath.Join(stateDir, "console.log"), []byte(strings.Join(logLines, "\n")+"\n"), 0o644); err != nil {
			t.Fatal(err)
		}

		var out bytes.Buffer
		if err := renderInstancePreview(root, "work-1", &out); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		got := out.String()
		for _, want := range []string{
			"Name:  work-1",
			"State: running",
			fmt.Sprintf("PID:   %d", pid),
			"Port:  2223",
			"Mount: plain + mount /tmp/my-worktree",
			"--- console.log (tail) ---",
			"boot line 11",
			"boot line 50",
		} {
			if !strings.Contains(got, want) {
				t.Errorf("preview missing %q in:\n%s", want, got)
			}
		}
		if strings.Contains(got, "boot line 10\n") {
			t.Errorf("preview should only include last 40 lines:\n%s", got)
		}
	})
}

func TestRunMenuLoop(t *testing.T) {
	t.Parallel()

	t.Run("enter on running instance connects via ssh and exits", func(t *testing.T) {
		t.Parallel()
		var sshTarget string
		ui := menuUI{
			listInstances: func(string) ([]instanceInfo, error) {
				return []instanceInfo{{name: "alpha", running: true, pid: 100, port: 2221}}, nil
			},
			selectItem: func([]string, io.Reader, io.Writer) (menuChoice, error) {
				return menuChoice{Key: "", Name: "alpha"}, nil
			},
			runSSH: func(_ string, name string) error {
				sshTarget = name
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runMenuLoop("/tmp/root", "/bin/microvm-sandbox", ui, &stdout, &stderr); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if sshTarget != "alpha" {
			t.Errorf("got sshTarget=%q, want %q", sshTarget, "alpha")
		}
	})

	t.Run("ctrl-d confirms with default yes, downs instance, and stays in TUI", func(t *testing.T) {
		t.Parallel()
		step := 0
		var confirmCalls []bool
		var downed []string

		ui := menuUI{
			listInstances: func(string) ([]instanceInfo, error) {
				if len(downed) == 0 {
					return []instanceInfo{
						{name: "alpha", running: true, pid: 100, port: 2221},
						{name: "beta", running: false, port: 2222},
					}, nil
				}
				return []instanceInfo{{name: "beta", running: false, port: 2222}}, nil
			},
			selectItem: func([]string, io.Reader, io.Writer) (menuChoice, error) {
				step++
				switch step {
				case 1:
					return menuChoice{Key: "ctrl-d", Name: "alpha"}, nil
				case 2:
					return menuChoice{Key: "ctrl-d", Name: "beta"}, nil
				default:
					return menuChoice{}, errMenuCanceled
				}
			},
			confirm: func(_ string, defaultYes bool, _ io.Writer) (bool, error) {
				confirmCalls = append(confirmCalls, defaultYes)
				return len(confirmCalls) == 1, nil
			},
			runDown: func(_ string, name string, _ io.Writer) error {
				downed = append(downed, name)
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runMenuLoop("/tmp/root", "/bin/microvm-sandbox", ui, &stdout, &stderr); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if step != 3 {
			t.Errorf("expected 3 fzf loops (down, declined down, cancel), got %d", step)
		}
		if !slices.Equal(confirmCalls, []bool{true, true}) {
			t.Errorf("confirm defaultYes flags = %v, want [true true]", confirmCalls)
		}
		if !slices.Equal(downed, []string{"alpha"}) {
			t.Errorf("downed = %v, want [alpha]", downed)
		}
	})

	t.Run("ctrl-a starts instance from empty list and loops back", func(t *testing.T) {
		t.Parallel()
		step := 0
		var upArgs []string

		ui := menuUI{
			listInstances: func(string) ([]instanceInfo, error) {
				return nil, nil
			},
			selectItem: func([]string, io.Reader, io.Writer) (menuChoice, error) {
				step++
				if step == 1 {
					return menuChoice{Key: "ctrl-a"}, nil
				}
				return menuChoice{}, errMenuCanceled
			},
			inputText: func(_, _ string, _ io.Writer) (string, error) {
				return "work-1", nil
			},
			chooseAction: func(_ string, _ []string, _ io.Writer) (string, error) {
				return menuUpModeMountCWD, nil
			},
			getwd: func() (string, error) {
				return "/tmp/project", nil
			},
			runUp: func(args []string, _, _ io.Writer) error {
				upArgs = append([]string(nil), args...)
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runMenuLoop("/tmp/root", "/bin/microvm-sandbox", ui, &stdout, &stderr); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if step != 2 {
			t.Errorf("expected 2 fzf loops (up then cancel), got %d", step)
		}
		wantArgs := []string{"--plain", "--mount", "/tmp/project", "work-1"}
		if !slices.Equal(upArgs, wantArgs) {
			t.Errorf("upArgs = %v, want %v", upArgs, wantArgs)
		}
	})

	t.Run("ctrl-x down all confirms with default false and stays in TUI", func(t *testing.T) {
		t.Parallel()
		step := 0
		var defaultYesSeen bool
		downAllCalled := false

		ui := menuUI{
			listInstances: func(string) ([]instanceInfo, error) {
				return []instanceInfo{{name: "alpha", running: true, pid: 100, port: 2221}}, nil
			},
			selectItem: func([]string, io.Reader, io.Writer) (menuChoice, error) {
				step++
				if step == 1 {
					return menuChoice{Key: "ctrl-x", Name: "alpha"}, nil
				}
				return menuChoice{}, errMenuCanceled
			},
			chooseAction: func(_ string, options []string, _ io.Writer) (string, error) {
				if !slices.Contains(options, menuActionDownAll) {
					t.Errorf("missing %q in options %v", menuActionDownAll, options)
				}
				return menuActionDownAll, nil
			},
			confirm: func(_ string, defaultYes bool, _ io.Writer) (bool, error) {
				defaultYesSeen = defaultYes
				return true, nil
			},
			runDownAll: func(_ string, _ io.Writer) error {
				downAllCalled = true
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runMenuLoop("/tmp/root", "/bin/microvm-sandbox", ui, &stdout, &stderr); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if defaultYesSeen {
			t.Errorf("down all confirm should default to false")
		}
		if !downAllCalled {
			t.Errorf("expected runDownAll to be called")
		}
		if step != 2 {
			t.Errorf("expected 2 fzf loops, got %d", step)
		}
	})

	t.Run("enter on stopped instance opens action menu without ssh option", func(t *testing.T) {
		t.Parallel()
		step := 0
		var seenOptions []string
		var downed string

		ui := menuUI{
			listInstances: func(string) ([]instanceInfo, error) {
				return []instanceInfo{{name: "stale", running: false, port: 2222}}, nil
			},
			selectItem: func([]string, io.Reader, io.Writer) (menuChoice, error) {
				step++
				if step == 1 {
					return menuChoice{Key: "", Name: "stale"}, nil
				}
				return menuChoice{}, errMenuCanceled
			},
			chooseAction: func(_ string, options []string, _ io.Writer) (string, error) {
				seenOptions = append([]string(nil), options...)
				return menuActionDown, nil
			},
			confirm: func(_ string, defaultYes bool, _ io.Writer) (bool, error) {
				if !defaultYes {
					t.Errorf("expected defaultYes=true for single down")
				}
				return true, nil
			},
			runDown: func(_ string, name string, _ io.Writer) error {
				downed = name
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runMenuLoop("/tmp/root", "/bin/microvm-sandbox", ui, &stdout, &stderr); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if slices.Contains(seenOptions, menuActionSSH) {
			t.Errorf("stopped instance action menu should not offer SSH: %v", seenOptions)
		}
		if downed != "stale" {
			t.Errorf("got downed=%q, want %q", downed, "stale")
		}
	})
}

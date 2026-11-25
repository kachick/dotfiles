package main

import (
	"bytes"
	"errors"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"
)

const sampleMicrovmRun = `#!/bin/bash
exec -a "microvm@sandbox" qemu-system-x86_64 -name sandbox -chardev 'stdio,id=stdio,signal=off' -serial chardev:stdio -fsdev 'local,id=fs0,path=/nix/store,security_model=none,readonly=true' -device 'virtio-9p-pci,fsdev=fs0,mount_tag=ro-store' -fsdev 'local,id=fs2,path=/home/kachick/repos/github.com/kachick,security_model=none,readonly=false' -device 'virtio-9p-pci,fsdev=fs2,mount_tag=repos' -netdev 'user,id=net0'
`

func TestValidateName(t *testing.T) {
	t.Parallel()

	valid := []string{"default", "fix-lint-a1b2c3", "test_1.2"}
	for _, name := range valid {
		if err := validateName(name); err != nil {
			t.Errorf("validateName(%q) unexpected error: %v", name, err)
		}
	}

	invalid := []string{"", "../escape", "bad name", "foo/bar", "a'b"}
	for _, name := range invalid {
		if err := validateName(name); err == nil {
			t.Errorf("validateName(%q) expected error, got nil", name)
		}
	}
}

func TestParseUpArgs(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name      string
		args      []string
		want      upOptions
		wantError bool
	}{
		{
			name: "default",
			args: nil,
			want: upOptions{name: defaultName},
		},
		{
			name: "named",
			args: []string{"test-1"},
			want: upOptions{name: "test-1"},
		},
		{
			name: "plain without mount",
			args: []string{"--plain", "task-a1b2c3"},
			want: upOptions{name: "task-a1b2c3", plain: true},
		},
		{
			name: "plain with mount",
			args: []string{"--plain", "--mount", "/tmp/wt", "task-a1b2c3"},
			want: upOptions{name: "task-a1b2c3", plain: true, mountDir: "/tmp/wt"},
		},
		{
			name: "mount implies plain",
			args: []string{"--mount", "/tmp/wt", "task-a1b2c3"},
			want: upOptions{name: "task-a1b2c3", plain: true, mountDir: "/tmp/wt"},
		},
		{
			name:      "extra positional arg",
			args:      []string{"--plain", "a", "b"},
			wantError: true,
		},
		{
			name:      "invalid instance name",
			args:      []string{"--plain", "../bad"},
			wantError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			got, err := parseUpArgs(tt.args)
			if tt.wantError {
				if err == nil {
					t.Fatalf("expected error, got %+v", got)
				}
				return
			}
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got != tt.want {
				t.Errorf("got %+v, want %+v", got, tt.want)
			}
		})
	}
}

func TestParseExecArgs(t *testing.T) {
	t.Parallel()

	name, cmd, err := parseExecArgs([]string{"--", "echo", "hi"})
	if err != nil || name != defaultName || strings.Join(cmd, " ") != "echo hi" {
		t.Fatalf("unexpected result: name=%q cmd=%v err=%v", name, cmd, err)
	}

	name, cmd, err = parseExecArgs([]string{"task-1", "--", "go", "test"})
	if err != nil || name != "task-1" || strings.Join(cmd, " ") != "go test" {
		t.Fatalf("unexpected result: name=%q cmd=%v err=%v", name, cmd, err)
	}

	for _, bad := range [][]string{nil, {"task-1"}, {"task-1", "echo"}, {"task-1", "--"}} {
		if _, _, err := parseExecArgs(bad); err == nil {
			t.Errorf("parseExecArgs(%v) expected error", bad)
		}
	}
}

func TestPatchRunnerContent(t *testing.T) {
	t.Parallel()

	t.Run("default keeps host repos mount", func(t *testing.T) {
		t.Parallel()
		got, err := patchRunnerContent(sampleMicrovmRun, patchOptions{
			name:     "dev-1",
			port:     2221,
			stateDir: "/run/user/1000/microvm-sandbox/dev-1",
		})
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if !strings.Contains(got, "-name 'sandbox-dev-1'") {
			t.Errorf("missing patched name: %s", got)
		}
		if !strings.Contains(got, "hostfwd=tcp:127.0.0.1:2221-:22") {
			t.Errorf("missing hostfwd: %s", got)
		}
		if !strings.Contains(got, "path="+hostReposPath) {
			t.Errorf("expected host repos mount preserved: %s", got)
		}
		if strings.Contains(got, "mount_tag=workspace") {
			t.Errorf("unexpected workspace mount in default mode: %s", got)
		}
	})

	t.Run("plain replaces repos with read-only empty dir", func(t *testing.T) {
		t.Parallel()
		got, err := patchRunnerContent(sampleMicrovmRun, patchOptions{
			name:     "agent-1",
			port:     2222,
			stateDir: "/run/user/1000/microvm-sandbox/agent-1",
			plain:    true,
		})
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if strings.Contains(got, hostReposPath) {
			t.Errorf("host repos path must not remain in plain mode: %s", got)
		}
		if !strings.Contains(got, "path=/run/user/1000/microvm-sandbox/agent-1/empty,security_model=none,readonly=true") {
			t.Errorf("missing empty read-only mount: %s", got)
		}
		if strings.Contains(got, "mount_tag=workspace") {
			t.Errorf("unexpected workspace mount without --mount: %s", got)
		}
	})

	t.Run("plain with mount adds workspace share", func(t *testing.T) {
		t.Parallel()
		got, err := patchRunnerContent(sampleMicrovmRun, patchOptions{
			name:     "agent-2",
			port:     2223,
			stateDir: "/run/user/1000/microvm-sandbox/agent-2",
			plain:    true,
			mountDir: "/home/kachick/repos/github.com/kachick/dotfiles/main",
		})
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if strings.Contains(got, "path="+hostReposPath+",") {
			t.Errorf("host repos root must not remain mounted: %s", got)
		}
		want := "-fsdev 'local,id=fs_workspace,path=/home/kachick/repos/github.com/kachick/dotfiles/main,security_model=none,readonly=false' -device 'virtio-9p-pci,fsdev=fs_workspace,mount_tag=workspace'"
		if !strings.Contains(got, want) {
			t.Errorf("missing workspace share %q in %s", want, got)
		}
	})

	t.Run("rejects unsafe characters in mount path", func(t *testing.T) {
		t.Parallel()
		_, err := patchRunnerContent(sampleMicrovmRun, patchOptions{
			name:     "agent-3",
			port:     2224,
			stateDir: "/run/user/1000/microvm-sandbox/agent-3",
			plain:    true,
			mountDir: "/tmp/bad,path",
		})
		if err == nil {
			t.Fatal("expected error for comma in mount path")
		}
	})
}

func TestValidateMountPath(t *testing.T) {
	t.Parallel()

	dir := t.TempDir()
	got, err := validateMountPath(dir)
	if err != nil {
		t.Fatalf("validateMountPath(%q) unexpected error: %v", dir, err)
	}
	if got != dir {
		t.Errorf("got %q, want %q", got, dir)
	}

	file := filepath.Join(dir, "file.txt")
	if err := os.WriteFile(file, []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	if _, err := validateMountPath(file); err == nil {
		t.Errorf("expected error for non-directory path")
	}
}

func TestRunSubcommands(t *testing.T) {
	t.Parallel()

	t.Run("no args prints usage to stderr and returns error", func(t *testing.T) {
		t.Parallel()
		var stdout, stderr bytes.Buffer
		err := run(nil, &stdout, &stderr)
		if err == nil {
			t.Fatal("expected error for missing subcommand")
		}
		if stdout.Len() != 0 {
			t.Errorf("expected empty stdout, got %q", stdout.String())
		}
		if !strings.Contains(stderr.String(), "microvm-sandbox console") {
			t.Errorf("expected usage text in stderr, got %q", stderr.String())
		}
	})

	t.Run("help prints usage to stdout", func(t *testing.T) {
		t.Parallel()
		var stdout, stderr bytes.Buffer
		if err := run([]string{"--help"}, &stdout, &stderr); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if stdout.String() != usageText {
			t.Errorf("got stdout %q, want %q", stdout.String(), usageText)
		}
		if stderr.Len() != 0 {
			t.Errorf("expected empty stderr, got %q", stderr.String())
		}
	})

	t.Run("unknown subcommand prints usage to stderr and returns error", func(t *testing.T) {
		t.Parallel()
		var stdout, stderr bytes.Buffer
		if err := run([]string{"bogus"}, &stdout, &stderr); err == nil {
			t.Fatal("expected error for unknown subcommand")
		}
		if stderr.String() != usageText {
			t.Errorf("got stderr %q, want %q", stderr.String(), usageText)
		}
	})
}

func TestProbeSSHBanner(t *testing.T) {
	t.Parallel()

	t.Run("accepts SSH banner", func(t *testing.T) {
		t.Parallel()
		ln, err := net.Listen("tcp", "127.0.0.1:0")
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = ln.Close() }()

		go func() {
			conn, err := ln.Accept()
			if err != nil {
				return
			}
			_, _ = conn.Write([]byte("SSH-2.0-OpenSSH_10.6\r\n"))
			_ = conn.Close()
		}()

		if !probeSSHBanner(ln.Addr().String(), time.Second) {
			t.Fatal("expected probeSSHBanner to succeed")
		}
	})

	t.Run("rejects immediate EOF like unready SLiRP port", func(t *testing.T) {
		t.Parallel()
		ln, err := net.Listen("tcp", "127.0.0.1:0")
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = ln.Close() }()

		go func() {
			conn, err := ln.Accept()
			if err != nil {
				return
			}
			_ = conn.Close()
		}()

		if probeSSHBanner(ln.Addr().String(), time.Second) {
			t.Fatal("expected probeSSHBanner to fail on immediate EOF")
		}
	})

	t.Run("rejects non-SSH banner", func(t *testing.T) {
		t.Parallel()
		ln, err := net.Listen("tcp", "127.0.0.1:0")
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = ln.Close() }()

		go func() {
			conn, err := ln.Accept()
			if err != nil {
				return
			}
			_, _ = conn.Write([]byte("HTTP/1.1 200 OK\r\n"))
			_ = conn.Close()
		}()

		if probeSSHBanner(ln.Addr().String(), time.Second) {
			t.Fatal("expected probeSSHBanner to fail on non-SSH response")
		}
	})
}

func TestListRunningInstances(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	pid := os.Getpid()

	runningDir := filepath.Join(root, "alpha")
	if err := os.MkdirAll(runningDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(runningDir, "qemu.pid"), []byte(strconv.Itoa(pid)+"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(runningDir, "ssh.port"), []byte("2221\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	stoppedDir := filepath.Join(root, "beta")
	if err := os.MkdirAll(stoppedDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(stoppedDir, "ssh.port"), []byte("2222\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	missingPortDir := filepath.Join(root, "gamma")
	if err := os.MkdirAll(missingPortDir, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(missingPortDir, "qemu.pid"), []byte(strconv.Itoa(pid)+"\n"), 0o644); err != nil {
		t.Fatal(err)
	}

	got, err := listRunningInstances(root)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(got) != 1 {
		t.Fatalf("got %d running instances, want 1: %+v", len(got), got)
	}
	if got[0].name != "alpha" || got[0].pid != pid || got[0].port != 2221 || !got[0].running {
		t.Errorf("unexpected instance: %+v", got[0])
	}
}

func TestPickInstanceWithFzf(t *testing.T) {
	t.Parallel()

	t.Run("errors when no running instances", func(t *testing.T) {
		t.Parallel()
		if _, err := pickInstanceWithFzf(nil, "fzf"); err == nil {
			t.Fatal("expected error for empty instances")
		}
	})

	t.Run("returns selected instance name from fzf output", func(t *testing.T) {
		t.Parallel()
		fakeFzf := filepath.Join(t.TempDir(), "fzf")
		script := "#!/bin/sh\nsed -n '2p'\n"
		if err := os.WriteFile(fakeFzf, []byte(script), 0o755); err != nil {
			t.Fatal(err)
		}

		instances := []instanceInfo{
			{name: "alpha", running: true, pid: 1001, port: 2221},
			{name: "work-1", running: true, pid: 1002, port: 2222},
		}
		got, err := pickInstanceWithFzf(instances, fakeFzf)
		if err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
		if got != "work-1" {
			t.Errorf("got %q, want %q", got, "work-1")
		}
	})

	t.Run("propagates fzf cancel exit code", func(t *testing.T) {
		t.Parallel()
		fakeFzf := filepath.Join(t.TempDir(), "fzf")
		script := "#!/bin/sh\nexit 130\n"
		if err := os.WriteFile(fakeFzf, []byte(script), 0o755); err != nil {
			t.Fatal(err)
		}

		instances := []instanceInfo{
			{name: "alpha", running: true, pid: 1001, port: 2221},
		}
		_, err := pickInstanceWithFzf(instances, fakeFzf)
		var exitErr *exec.ExitError
		if !errors.As(err, &exitErr) || exitErr.ExitCode() != 130 {
			t.Fatalf("got err=%v, want ExitError with code 130", err)
		}
	})
}

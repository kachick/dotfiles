package main

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestClassifyChanges(t *testing.T) {
	tests := []struct {
		name         string
		event        string
		target       string
		changedFiles []string
		want         changeResult
	}{
		{
			name:         "schedule runs all build jobs",
			event:        "schedule",
			changedFiles: nil,
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       true,
				FlakeLock:   false,
			},
		},
		{
			name:         "workflow_dispatch default all runs all build jobs",
			event:        "workflow_dispatch",
			target:       "all",
			changedFiles: nil,
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       true,
				FlakeLock:   false,
			},
		},
		{
			name:         "workflow_dispatch target nixos runs only nixos",
			event:        "workflow_dispatch",
			target:       "nixos",
			changedFiles: nil,
			want: changeResult{
				Packages:    false,
				HomeManager: false,
				Nixos:       true,
				FlakeLock:   false,
			},
		},
		{
			name:         "workflow_dispatch target home-manager runs only home-manager",
			event:        "workflow_dispatch",
			target:       "home-manager",
			changedFiles: nil,
			want: changeResult{
				Packages:    false,
				HomeManager: true,
				Nixos:       false,
				FlakeLock:   false,
			},
		},
		{
			name:         "workflow_dispatch target packages runs only packages",
			event:        "workflow_dispatch",
			target:       "packages",
			changedFiles: nil,
			want: changeResult{
				Packages:    true,
				HomeManager: false,
				Nixos:       false,
				FlakeLock:   false,
			},
		},
		{
			name:         "workflow_dispatch target nixos-iso skips regular build jobs",
			event:        "workflow_dispatch",
			target:       "nixos-iso",
			changedFiles: nil,
			want: changeResult{
				Packages:    false,
				HomeManager: false,
				Nixos:       false,
				FlakeLock:   false,
			},
		},
		{
			name:         "empty changed files on push fails closed",
			event:        "push",
			changedFiles: nil,
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       true,
				Container:   true,
				FlakeLock:   false,
			},
		},
		{
			name:         "devshell or taskfile only skips packages, home-manager, and nixos",
			event:        "pull_request",
			changedFiles: []string{"Taskfile.yml", "devShells.nix", "cmd/lint/main.go"},
			want: changeResult{
				Packages:    false,
				HomeManager: false,
				Nixos:       false,
				FlakeLock:   false,
			},
		},
		{
			name:         "pkgs change runs packages and home-manager but skips nixos",
			event:        "pull_request",
			changedFiles: []string{"pkgs/by-name/an/antigravity-cli/package.nix"},
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       false,
				FlakeLock:   false,
			},
		},
		{
			name:         "config or typos.toml change runs packages, home-manager, and container on push",
			event:        "push",
			changedFiles: []string{"config/mozc/ibus_config.textproto", "typos.toml"},
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       false,
				Container:   true,
				FlakeLock:   false,
			},
		},
		{
			name:         "microvm-sandbox change runs packages and home-manager",
			event:        "pull_request",
			changedFiles: []string{"cmd/microvm-sandbox/main.go"},
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       false,
				FlakeLock:   false,
			},
		},
		{
			name:         "ci-build change runs packages and home-manager but skips nixos and container",
			event:        "push",
			changedFiles: []string{"cmd/ci-build/main.go", "cmd/ci-build/main_test.go"},
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       false,
				Container:   false,
				FlakeLock:   false,
			},
		},
		{
			name:         "home-manager only change runs home-manager and skips packages and nixos",
			event:        "pull_request",
			changedFiles: []string{"home-manager/zsh.nix"},
			want: changeResult{
				Packages:    false,
				HomeManager: true,
				Nixos:       false,
				FlakeLock:   false,
			},
		},
		{
			name:         "nixos only change runs nixos and skips packages and home-manager",
			event:        "pull_request",
			changedFiles: []string{"nixos/modules/cloudflare-warp.nix"},
			want: changeResult{
				Packages:    false,
				HomeManager: false,
				Nixos:       true,
				FlakeLock:   false,
			},
		},
		{
			name:         "containers only change on push runs only container",
			event:        "push",
			changedFiles: []string{"containers/build.bash"},
			want: changeResult{
				Packages:    false,
				HomeManager: false,
				Nixos:       false,
				Container:   true,
				FlakeLock:   false,
			},
		},
		{
			name:         "containers markdown change on push skips container",
			event:        "push",
			changedFiles: []string{"containers/README.md"},
			want: changeResult{
				Packages:    false,
				HomeManager: false,
				Nixos:       false,
				Container:   false,
				FlakeLock:   false,
			},
		},
		{
			name:         "nixos host unrelated to container on push skips container",
			event:        "push",
			changedFiles: []string{"nixos/hosts/wsl/default.nix"},
			want: changeResult{
				Packages:    false,
				HomeManager: false,
				Nixos:       true,
				Container:   false,
				FlakeLock:   false,
			},
		},
		{
			name:         "flake.lock on pull_request runs all jobs including diff",
			event:        "pull_request",
			changedFiles: []string{"flake.lock"},
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       true,
				FlakeLock:   true,
			},
		},
		{
			name:         "flake.lock on push runs all build jobs including container without PR diff",
			event:        "push",
			changedFiles: []string{"flake.lock"},
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       true,
				Container:   true,
				FlakeLock:   false,
			},
		},
		{
			name:         "overlays change runs all build jobs",
			event:        "pull_request",
			changedFiles: []string{"overlays/pinned.nix"},
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       true,
				FlakeLock:   false,
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := classifyChanges(tt.event, tt.target, tt.changedFiles)
			if got != tt.want {
				t.Errorf("classifyChanges(%q, %q, %v) = %+v, want %+v", tt.event, tt.target, tt.changedFiles, got, tt.want)
			}
		})
	}
}

func TestRunChanges_FormatOutput(t *testing.T) {
	var buf bytes.Buffer
	if err := runChanges([]string{"--event=schedule"}, &buf); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	got := buf.String()
	for _, expectedLine := range []string{
		"packages=true",
		"home-manager=true",
		"nixos=true",
		"container=false",
		"flake-lock=false",
	} {
		if !strings.Contains(got, expectedLine+"\n") {
			t.Errorf("expected output %q to contain line %q", got, expectedLine)
		}
	}
}

func TestRunChanges_PushMultiCommitRange(t *testing.T) {
	dir := t.TempDir()
	runGit := func(args ...string) string {
		t.Helper()
		cmd := exec.Command("git", args...)
		cmd.Dir = dir
		cmd.Env = append(os.Environ(),
			"GIT_AUTHOR_NAME=Test",
			"GIT_AUTHOR_EMAIL=test@example.com",
			"GIT_COMMITTER_NAME=Test",
			"GIT_COMMITTER_EMAIL=test@example.com",
			"GIT_CONFIG_GLOBAL=/dev/null",
			"GIT_CONFIG_SYSTEM=/dev/null",
		)
		out, err := cmd.CombinedOutput()
		if err != nil {
			t.Fatalf("git %v failed: %v\n%s", args, err, out)
		}
		return strings.TrimSpace(string(out))
	}

	writeFile := func(rel, content string) {
		t.Helper()
		full := filepath.Join(dir, rel)
		if err := os.MkdirAll(filepath.Dir(full), 0o755); err != nil {
			t.Fatalf("mkdir %s: %v", rel, err)
		}
		if err := os.WriteFile(full, []byte(content), 0o644); err != nil {
			t.Fatalf("write %s: %v", rel, err)
		}
	}

	runGit("init")
	writeFile("README.md", "init\n")
	runGit("add", ".")
	runGit("commit", "--no-gpg-sign", "-m", "Initial commit")
	beforeSHA := runGit("rev-parse", "HEAD")

	// Earlier commit in the same push changes home-manager and nixos
	writeFile("home-manager/default.nix", "{ }\n")
	writeFile("nixos/desktop/game-unfree.nix", "{ }\n")
	runGit("add", ".")
	runGit("commit", "--no-gpg-sign", "-m", "Update home-manager and nixos")

	// Final commit in the same push changes only containers/
	writeFile("containers/base-image.json", "{}\n")
	runGit("add", ".")
	runGit("commit", "--no-gpg-sign", "-m", "Update container base image")

	t.Chdir(dir)
	t.Setenv("BASE_SHA", beforeSHA)

	var buf bytes.Buffer
	if err := runChanges([]string{"--event=push"}, &buf); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	got := buf.String()
	for _, expectedLine := range []string{
		"packages=false",
		"home-manager=true",
		"nixos=true",
		"container=true",
		"flake-lock=false",
	} {
		if !strings.Contains(got, expectedLine+"\n") {
			t.Errorf("expected output:\n%s\nto contain %q", got, expectedLine)
		}
	}
}

func TestRunChanges_PushZeroBaseSHAFailsClosed(t *testing.T) {
	t.Setenv("BASE_SHA", strings.Repeat("0", 40))

	var buf bytes.Buffer
	if err := runChanges([]string{"--event=push"}, &buf); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	got := buf.String()
	for _, expectedLine := range []string{
		"packages=true",
		"home-manager=true",
		"nixos=true",
		"container=true",
		"flake-lock=false",
	} {
		if !strings.Contains(got, expectedLine+"\n") {
			t.Errorf("expected output:\n%s\nto contain %q", got, expectedLine)
		}
	}
}

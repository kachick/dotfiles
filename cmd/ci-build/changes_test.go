package main

import (
	"bytes"
	"strings"
	"testing"
)

func TestClassifyChanges(t *testing.T) {
	tests := []struct {
		name         string
		event        string
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
			name:         "workflow_dispatch runs all build jobs",
			event:        "workflow_dispatch",
			changedFiles: nil,
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       true,
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
			name:         "config or typos.toml change runs packages and home-manager but skips nixos",
			event:        "push",
			changedFiles: []string{"config/mozc/ibus_config.textproto", "typos.toml"},
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       false,
				FlakeLock:   false,
			},
		},
		{
			name:         "ci-build change runs packages and home-manager but skips nixos",
			event:        "push",
			changedFiles: []string{"cmd/ci-build/main.go", "cmd/ci-build/main_test.go"},
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       false,
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
			name:         "flake.lock on push runs all build jobs without PR diff",
			event:        "push",
			changedFiles: []string{"flake.lock"},
			want: changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       true,
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
			got := classifyChanges(tt.event, tt.changedFiles)
			if got != tt.want {
				t.Errorf("classifyChanges(%q, %v) = %+v, want %+v", tt.event, tt.changedFiles, got, tt.want)
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
		"flake-lock=false",
	} {
		if !strings.Contains(got, expectedLine+"\n") {
			t.Errorf("expected output %q to contain line %q", got, expectedLine)
		}
	}
}

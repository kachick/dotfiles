package main

import (
	"os/exec"
	"testing"
)

func TestGetCurrentNixSystem(t *testing.T) {
	if _, err := exec.LookPath("nix"); err != nil {
		t.Skip("skipping test: nix is not installed in PATH")
	}

	sys, err := getCurrentNixSystem()
	if err != nil {
		t.Fatalf("unexpected error getting current nix system: %v", err)
	}
	if sys == "" {
		t.Error("expected non-empty nix system, got empty string")
	}
}

func TestRunPackage_MissingArg(t *testing.T) {
	err := runPackage([]string{})
	if err == nil {
		t.Error("expected error when package name is missing, got nil")
	}
}

func TestRunNixos_MissingArg(t *testing.T) {
	err := runNixos([]string{})
	if err == nil {
		t.Error("expected error when host name is missing, got nil")
	}
}

func TestIsPackageFree(t *testing.T) {
	if _, err := exec.LookPath("nix"); err != nil {
		t.Skip("skipping test: nix is not installed in PATH")
	}

	sys, err := getCurrentNixSystem()
	if err != nil {
		t.Fatalf("unexpected error getting current nix system: %v", err)
	}

	tests := []struct {
		pkg  string
		want bool
	}{
		{pkg: "archive-home-files", want: true},
		{pkg: "antigravity-cli", want: false},
		{pkg: "ludii-bin", want: false},
	}

	for _, tt := range tests {
		t.Run(tt.pkg, func(t *testing.T) {
			got, err := isPackageFree(tt.pkg, sys)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got != tt.want {
				t.Errorf("isPackageFree(%q, %q) = %v, want %v", tt.pkg, sys, got, tt.want)
			}
		})
	}
}

func TestIsCacheableStorePath(t *testing.T) {
	tests := []struct {
		path string
		want bool
	}{
		{path: "/nix/store/abc-hello-1.0", want: true},
		{path: "/nix/store/abc-git-2.40.0", want: true},
		{path: "/nix/store/abc-libfoo.so.1", want: true},
		{path: "/nix/store/abc-source", want: false},
		{path: "/nix/store/abc-foo-source", want: false},
		{path: "/nix/store/abc-vendor", want: false},
		{path: "/nix/store/abc-go-modules-vendor", want: false},
		{path: "/nix/store/abc-nixos.iso", want: false},
		{path: "/nix/store/abc-image.iso", want: false},
		{path: "/nix/store/abc-nixpkgs.tar.gz", want: false},
	}

	for _, tt := range tests {
		t.Run(tt.path, func(t *testing.T) {
			got := isCacheableStorePath(tt.path)
			if got != tt.want {
				t.Errorf("isCacheableStorePath(%q) = %v, want %v", tt.path, got, tt.want)
			}
		})
	}
}

func TestFilterCacheablePaths(t *testing.T) {
	input := []string{
		"/nix/store/abc-bin",
		"/nix/store/abc-source",
		"/nix/store/abc-bin", // duplicate
		"/nix/store/abc-vendor",
		"", // empty
		"/nix/store/abc-lib",
		"/nix/store/abc-install.iso",
	}

	want := []string{
		"/nix/store/abc-bin",
		"/nix/store/abc-lib",
	}

	got := filterCacheablePaths(input)
	if len(got) != len(want) {
		t.Fatalf("filterCacheablePaths() length = %d, want %d (got: %v)", len(got), len(want), got)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("filterCacheablePaths()[%d] = %q, want %q", i, got[i], want[i])
		}
	}
}

func TestRunPush_MissingArg(t *testing.T) {
	err := runPush([]string{})
	if err == nil {
		t.Error("expected error when path is missing, got nil")
	}
}

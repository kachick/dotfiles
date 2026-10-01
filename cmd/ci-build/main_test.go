package main

import (
	"os/exec"
	"strings"
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

func TestGetAllPackageLicenses(t *testing.T) {
	if _, err := exec.LookPath("nix"); err != nil {
		t.Skip("skipping test: nix is not installed in PATH")
	}

	sys, err := getCurrentNixSystem()
	if err != nil {
		t.Fatalf("unexpected error getting current nix system: %v", err)
	}

	repoRootBytes, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		t.Fatalf("failed to detect repository root: %v", err)
	}
	repoRoot := strings.TrimSpace(string(repoRootBytes))

	licenses, err := getAllPackageLicenses(repoRoot, sys)
	if err != nil {
		t.Fatalf("getAllPackageLicenses failed: %v", err)
	}

	if free, ok := licenses["archive-home-files"]; !ok || !free {
		t.Errorf("expected archive-home-files to be free, got %v", free)
	}
	if free, ok := licenses["antigravity-cli"]; !ok || free {
		t.Errorf("expected antigravity-cli to be unfree, got %v", free)
	}
}

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

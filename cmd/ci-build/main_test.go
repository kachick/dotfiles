package main

import (
	"testing"
)

func TestGetCurrentNixSystem(t *testing.T) {
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

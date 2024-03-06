package config

import (
	"path/filepath"
	"testing"
)

func TestAssets(t *testing.T) {
	_, err := WindowsAssets.ReadFile(filepath.Join("starship", "starship.toml"))
	if err != nil {
		t.Fatalf("embed file not found: %v", err)
	}
}

package main

import (
	"testing"

	"github.com/kachick/dotfiles/config"
)

func TestAssets(t *testing.T) {
	for _, p := range provisioners("dummy_path") {
		_, err := config.WindowsAssets.ReadFile(p.EmbedPath())
		if err != nil {
			t.Fatalf("embed file not found: %v", err)
		}
	}
}

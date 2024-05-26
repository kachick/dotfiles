package main

import (
	"testing"

	"github.com/kachick/dotfiles"
)

func TestAssets(t *testing.T) {
	for _, p := range provisioners() {
		_, err := dotfiles.WindowsAssets.ReadFile(p.EmbedPath())
		if err != nil {
			t.Fatalf("embed file not found: %v", err)
		}
	}
}

package fileutils

import (
	"os"
	"path/filepath"
	"slices"
	"testing"
)

func TestWalkerFiltersFilesAndSkipsDirectories(t *testing.T) {
	root := t.TempDir()

	dirs := []string{
		"bash-dir",
		"config",
		"dist",
	}
	for _, d := range dirs {
		if err := os.MkdirAll(filepath.Join(root, d), 0o755); err != nil {
			t.Fatalf("mkdir %s: %v", d, err)
		}
	}

	files := []string{
		"script.bash",
		"bash-dir/nested.bash",
		"config/app.desktop",
		"default.nix",
		"bash.nix",
		"dist/ignored.bash",
		"dist/ignored.desktop",
	}
	for _, f := range files {
		if err := os.WriteFile(filepath.Join(root, f), []byte(""), 0o644); err != nil {
			t.Fatalf("write %s: %v", f, err)
		}
	}

	w, err := GetWalkerIn(root)
	if err != nil {
		t.Fatalf("GetWalkerIn failed: %v", err)
	}

	gotBash := w.GetAllBash()
	wantBash := []string{
		filepath.Join(root, "bash-dir/nested.bash"),
		filepath.Join(root, "script.bash"),
	}
	slices.Sort(gotBash)
	slices.Sort(wantBash)
	if !slices.Equal(gotBash, wantBash) {
		t.Errorf("GetAllBash() = %v, want %v", gotBash, wantBash)
	}

	gotNix := w.GetAllNix()
	wantNix := []string{
		filepath.Join(root, "bash.nix"),
		filepath.Join(root, "default.nix"),
	}
	slices.Sort(gotNix)
	slices.Sort(wantNix)
	if !slices.Equal(gotNix, wantNix) {
		t.Errorf("GetAllNix() = %v, want %v", gotNix, wantNix)
	}

	gotDesktop := w.GetAllDesktop()
	wantDesktop := []string{
		filepath.Join(root, "config/app.desktop"),
	}
	if !slices.Equal(gotDesktop, wantDesktop) {
		t.Errorf("GetAllDesktop() = %v, want %v", gotDesktop, wantDesktop)
	}
}

func TestGetWalkerInMissingRoot(t *testing.T) {
	_, err := GetWalkerIn(filepath.Join(t.TempDir(), "does-not-exist"))
	if err == nil {
		t.Fatal("expected error for missing root, got nil")
	}
}

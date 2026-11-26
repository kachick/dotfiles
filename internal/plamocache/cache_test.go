package plamocache

import (
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestDir(t *testing.T) {
	base := t.TempDir()
	t.Setenv("XDG_CACHE_HOME", base)

	got, err := Dir()
	if err != nil {
		t.Fatalf("Dir failed: %v", err)
	}
	want := filepath.Join(base, "plamo", "translations")
	if got != want {
		t.Errorf("Dir() = %q, want %q", got, want)
	}
}

func TestReadWriteAndTouch(t *testing.T) {
	cacheDir := filepath.Join(t.TempDir(), "translations")
	key1 := Key("prompt-a", "Add feature")
	key2 := Key("prompt-b", "Add feature")
	if key1 == key2 {
		t.Fatalf("expected distinct cache keys for different prompts, got %q", key1)
	}

	if _, ok := Read(cacheDir, key1); ok {
		t.Fatal("expected cache miss before write")
	}

	if err := Write(cacheDir, key1, "機能を追加\n"); err != nil {
		t.Fatalf("Write failed: %v", err)
	}

	path := Path(cacheDir, key1)
	oldTime := time.Now().Add(-48 * time.Hour)
	if err := os.Chtimes(path, oldTime, oldTime); err != nil {
		t.Fatalf("os.Chtimes failed: %v", err)
	}

	got, ok := Read(cacheDir, key1)
	if !ok {
		t.Fatal("expected cache hit after write")
	}
	if got != "機能を追加" {
		t.Errorf("Read = %q, want %q", got, "機能を追加")
	}

	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("os.Stat failed: %v", err)
	}
	if !info.ModTime().After(oldTime) {
		t.Errorf("expected mtime to be refreshed on cache hit: got %v, old %v", info.ModTime(), oldTime)
	}
}

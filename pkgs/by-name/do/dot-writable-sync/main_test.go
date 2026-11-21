package main

import (
	"encoding/json"
	"io/fs"
	"os"
	"path/filepath"
	"testing"
)

func TestParsePerm(t *testing.T) {
	tests := []struct {
		spec string
		base fs.FileMode
		want fs.FileMode
	}{
		{spec: "u+w", base: 0o444, want: 0o644},
		{spec: "u+w", base: 0o555, want: 0o755},
		{spec: "600", base: 0o444, want: 0o600},
		{spec: "0640", base: 0o444, want: 0o640},
		{spec: "u=rw,g=r,o=", base: 0o444, want: 0o640},
	}

	for _, tt := range tests {
		got, err := parsePerm(tt.spec, tt.base)
		if err != nil {
			t.Fatalf("parsePerm(%q, %o) error: %v", tt.spec, tt.base, err)
		}
		if got != tt.want {
			t.Errorf("parsePerm(%q, %o) = %o, want %o", tt.spec, tt.base, got, tt.want)
		}
	}
}

func TestRunSync_Lifecycle(t *testing.T) {
	tmp := t.TempDir()
	srcDir := filepath.Join(tmp, "store")
	dstDir := filepath.Join(tmp, "home")
	statePath := filepath.Join(tmp, "state", "state.json")
	if err := os.MkdirAll(srcDir, 0o755); err != nil {
		t.Fatal(err)
	}

	srcFile := filepath.Join(srcDir, "settings.json")
	dstFile := filepath.Join(dstDir, ".config", "zed", "settings.json")
	if err := os.WriteFile(srcFile, []byte("{\"v\":1}\n"), 0o444); err != nil {
		t.Fatal(err)
	}

	manifestPath := filepath.Join(tmp, "manifest.json")
	writeManifest := func(items []manifestItem) {
		t.Helper()
		b, err := json.Marshal(items)
		if err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(manifestPath, b, 0o644); err != nil {
			t.Fatal(err)
		}
	}

	writeManifest([]manifestItem{{Source: srcFile, Dest: dstFile, Perm: "u+w"}})
	if err := runSync(manifestPath, statePath, false); err != nil {
		t.Fatalf("initial runSync failed: %v", err)
	}

	info, err := os.Stat(dstFile)
	if err != nil {
		t.Fatalf("dstFile missing: %v", err)
	}
	if info.Mode().Perm() != 0o644 {
		t.Errorf("perm = %o, want 644", info.Mode().Perm())
	}

	// Simulate an existing read-only symlink replaced on migration.
	linkSrc := filepath.Join(srcDir, "secret")
	linkDst := filepath.Join(dstDir, ".ssh", "authorized_keys")
	if err := os.WriteFile(linkSrc, []byte("ssh-ed25519 AAA\n"), 0o444); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Dir(linkDst), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink("/nix/store/old-target", linkDst); err != nil {
		t.Fatal(err)
	}

	writeManifest([]manifestItem{{Source: linkSrc, Dest: linkDst, Perm: "600"}})
	if err := runSync(manifestPath, statePath, false); err != nil {
		t.Fatalf("symlink migration runSync failed: %v", err)
	}
	linkInfo, err := os.Lstat(linkDst)
	if err != nil {
		t.Fatal(err)
	}
	if (linkInfo.Mode() & os.ModeSymlink) != 0 {
		t.Fatalf("expected symlink to be replaced with regular file")
	}
	if linkInfo.Mode().Perm() != 0o600 {
		t.Errorf("perm = %o, want 600", linkInfo.Mode().Perm())
	}
}

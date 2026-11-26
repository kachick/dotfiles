package main

import (
	"io/fs"
	"os"
	"path/filepath"
	"testing"

	"github.com/kachick/dotfiles"
	"github.com/kachick/dotfiles/internal/configsync"
)

func TestAssets(t *testing.T) {
	for _, spec := range assetSpecs {
		p := spec.embedPath()
		if !spec.isDir {
			if _, err := dotfiles.WindowsAssets.ReadFile(p); err != nil {
				t.Fatalf("embed file not found: %s: %v", p, err)
			}
			continue
		}

		count := 0
		err := fs.WalkDir(dotfiles.WindowsAssets, p, func(walkPath string, d fs.DirEntry, err error) error {
			if err != nil {
				return err
			}
			if !d.IsDir() {
				count++
			}
			return nil
		})
		if err != nil {
			t.Fatalf("embed dir walk failed for %s: %v", p, err)
		}
		if count == 0 {
			t.Fatalf("embed dir %s is empty", p)
		}
	}
}

func TestResolveXdgConfigHome(t *testing.T) {
	tmp := t.TempDir()
	customXdg := filepath.Join(tmp, "custom-xdg")
	t.Setenv("XDG_CONFIG_HOME", customXdg)
	t.Setenv("LOCALAPPDATA", filepath.Join(tmp, "local-app-data"))

	resolver, err := newPathResolver(true)
	if err != nil {
		t.Fatalf("newPathResolver failed: %v", err)
	}

	got, err := resolver.resolveDst(assetSpec{
		embedTree: []string{"config", "starship", "starship.toml"},
		root:      rootXdgConfig,
		dstTree:   []string{"starship.toml"},
	})
	if err != nil {
		t.Fatalf("resolveDst failed: %v", err)
	}
	want := filepath.Join(customXdg, "starship.toml")
	if got != want {
		t.Errorf("resolveDst = %q, want %q", got, want)
	}
}

func TestBuildAndSyncManifest(t *testing.T) {
	tmp := t.TempDir()
	resolver := pathResolver{
		homePath:         filepath.Join(tmp, "home"),
		xdgConfigPath:    filepath.Join(tmp, "xdg"),
		appDataPath:      filepath.Join(tmp, "appdata"),
		localAppDataPath: filepath.Join(tmp, "localappdata"),
		pwshProfilePath:  filepath.Join(tmp, "Documents", "PowerShell", "Microsoft.PowerShell_profile.ps1"),
		tempDirPath:      filepath.Join(tmp, "tmp"),
	}

	entries, err := buildSyncEntries(resolver)
	if err != nil {
		t.Fatalf("buildSyncEntries failed: %v", err)
	}

	results, err := configsync.Sync(entries, configsync.Options{
		Conflict: configsync.ConflictSkip,
	})
	if err != nil {
		t.Fatalf("Sync failed: %v", err)
	}
	if len(results) < len(assetSpecs) {
		t.Fatalf("expected at least %d synced files, got %d", len(assetSpecs), len(results))
	}

	expectedPaths := []string{
		filepath.Join(resolver.xdgConfigPath, "alacritty", "themes", "iceberg-dark.toml"),
		filepath.Join(resolver.appDataPath, "Zed", "settings.json"),
		filepath.Join(resolver.localAppDataPath, "Packages", "Microsoft.WindowsTerminal_8wekyb3d8bbwe", "LocalState", "settings.json"),
		filepath.Join(resolver.localAppDataPath, "Microsoft", "WinGet", "Packages", "jtroo.kanata_gui_Microsoft.Winget.Source_8wekyb3d8bbwe", "kanata.kbd"),
		resolver.pwshProfilePath,
	}
	for _, p := range expectedPaths {
		if _, err := os.Stat(p); err != nil {
			t.Errorf("expected synced file %s: %v", p, err)
		}
	}
}

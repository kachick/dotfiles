package repocheck

import (
	"os"
	"path/filepath"
	"testing"
)

func TestCheckWorkflowPathsJSON(t *testing.T) {
	okJSON := []byte(`{"push":{"paths":["flake.nix","cmd/**"]},"pull_request":{"paths":["flake.nix","cmd/**"]}}`)
	if err := checkWorkflowPathsJSON(okJSON); err != nil {
		t.Fatalf("unexpected error for matching paths: %v", err)
	}

	diffJSON := []byte(`{"push":{"paths":["flake.nix","cmd/**"]},"pull_request":{"paths":["flake.nix"]}}`)
	if err := checkWorkflowPathsJSON(diffJSON); err == nil {
		t.Fatal("expected error for mismatched paths, got nil")
	}

	emptyJSON := []byte(`{"push":{"paths":[]},"pull_request":{"paths":[]}}`)
	if err := checkWorkflowPathsJSON(emptyJSON); err == nil {
		t.Fatal("expected error for empty paths, got nil")
	}
}

func TestCheckGoAndDprintVersions(t *testing.T) {
	writeFiles := func(t *testing.T, root, rootGo, winitGo, dprintLang, globalPluginVer string) {
		t.Helper()
		files := map[string]string{
			"go.mod":                     "module example.com/test\n\ngo " + rootGo + "\n",
			"cmd/winit-reg/go.mod":       "module example.com/test/winit\n\ngo " + winitGo + "\n",
			"dprint.jsonc":               `{"gofumpt":{"langVersion":"` + dprintLang + `"},"plugins":["npm:@dprint/json@0.25.2"]}`,
			"config/dprint/dprint.jsonc": "{\n  // comment with \"http://example.com\"\n  \"plugins\": [\"npm:@dprint/json@" + globalPluginVer + "\", \"npm:@dprint/ruff@0.11.2\"]\n}\n",
		}
		for rel, content := range files {
			full := filepath.Join(root, rel)
			if err := os.MkdirAll(filepath.Dir(full), 0o755); err != nil {
				t.Fatalf("mkdir %s: %v", rel, err)
			}
			if err := os.WriteFile(full, []byte(content), 0o644); err != nil {
				t.Fatalf("write %s: %v", rel, err)
			}
		}
	}

	t.Run("all match", func(t *testing.T) {
		root := t.TempDir()
		writeFiles(t, root, "1.27.3", "1.27.3", "go1.27", "0.25.2")
		if err := CheckGoAndDprintVersions(root); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
	})

	t.Run("winit go.mod mismatch", func(t *testing.T) {
		root := t.TempDir()
		writeFiles(t, root, "1.27.3", "1.26.0", "go1.27", "0.25.2")
		if err := CheckGoAndDprintVersions(root); err == nil {
			t.Fatal("expected error for winit-reg go.mod mismatch, got nil")
		}
	})

	t.Run("dprint gofumpt mismatch", func(t *testing.T) {
		root := t.TempDir()
		writeFiles(t, root, "1.27.3", "1.27.3", "go1.26", "0.25.2")
		if err := CheckGoAndDprintVersions(root); err == nil {
			t.Fatal("expected error for dprint gofumpt.langVersion mismatch, got nil")
		}
	})

	t.Run("dprint plugin mismatch", func(t *testing.T) {
		root := t.TempDir()
		writeFiles(t, root, "1.27.3", "1.27.3", "go1.27", "0.24.0")
		if err := CheckGoAndDprintVersions(root); err == nil {
			t.Fatal("expected error for dprint plugin mismatch, got nil")
		}
	})
}

func TestCheckByNamePrefixes(t *testing.T) {
	t.Run("valid layout", func(t *testing.T) {
		root := t.TempDir()
		for _, rel := range []string{
			"pkgs/by-name/gi/git-x/package.nix",
			"pkgs/by-name/p/p/package.nix",
		} {
			full := filepath.Join(root, rel)
			if err := os.MkdirAll(filepath.Dir(full), 0o755); err != nil {
				t.Fatalf("mkdir %s: %v", rel, err)
			}
			if err := os.WriteFile(full, []byte("{}"), 0o644); err != nil {
				t.Fatalf("write %s: %v", rel, err)
			}
		}
		if err := CheckByNamePrefixes(root); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}
	})

	t.Run("wrong prefix", func(t *testing.T) {
		root := t.TempDir()
		full := filepath.Join(root, "pkgs/by-name/xx/git-x/package.nix")
		if err := os.MkdirAll(filepath.Dir(full), 0o755); err != nil {
			t.Fatalf("mkdir: %v", err)
		}
		if err := os.WriteFile(full, []byte("{}"), 0o644); err != nil {
			t.Fatalf("write: %v", err)
		}
		if err := CheckByNamePrefixes(root); err == nil {
			t.Fatal("expected error for wrong by-name prefix, got nil")
		}
	})
}

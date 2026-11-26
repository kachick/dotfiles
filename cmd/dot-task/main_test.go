package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

type recordedCall struct {
	name string
	args []string
}

func testEnv(calls *[]recordedCall) env {
	return env{
		runCmd: func(name string, args ...string) error {
			*calls = append(*calls, recordedCall{name: name, args: args})
			return nil
		},
		cmdOutput: func(name string, args ...string) ([]byte, error) {
			if name == "nix" && len(args) >= 3 && args[2] == ".#nixosConfigurations" {
				return []byte(`["algae","moss","wsl"]`), nil
			}
			if name == "nix" && len(args) >= 3 && args[2] == ".#homeConfigurations" {
				return []byte(`["user@container","user@lima","user@wsl-ubuntu"]`), nil
			}
			return []byte(`[]`), nil
		},
		cmdExitOK: func(name string, args ...string) (bool, error) {
			return true, nil
		},
		selectItem: func(items []string, prompt, header string) (string, error) {
			return items[0], nil
		},
		isTerminal: func() bool {
			return true
		},
		fileExists: func(path string) bool {
			return false
		},
		hostname: func() (string, error) {
			return "moss", nil
		},
		getenv: func(key string) string {
			if key == "USER" {
				return "user"
			}
			return ""
		},
	}
}

func TestRunApply(t *testing.T) {
	t.Run("routes to nixos when /etc/NIXOS exists", func(t *testing.T) {
		var calls []recordedCall
		e := testEnv(&calls)
		e.fileExists = func(path string) bool { return path == nixosMarkerPath }

		if err := run([]string{"apply"}, e); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		want := []recordedCall{{
			name: "sudo",
			args: []string{"nixos-rebuild", "switch", "--flake", ".#moss", "--show-trace"},
		}}
		if !reflect.DeepEqual(calls, want) {
			t.Fatalf("calls = %+v, want %+v", calls, want)
		}
	})

	t.Run("routes to home-manager and falls back to fzf when hostname does not match", func(t *testing.T) {
		var calls []recordedCall
		e := testEnv(&calls)
		e.selectItem = func(items []string, prompt, header string) (string, error) {
			return "user@wsl-ubuntu", nil
		}

		if err := run([]string{"apply"}, e); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		want := []recordedCall{{
			name: "nix",
			args: []string{"run", ".#home-manager", "--", "switch", "-b", "backup", "--show-trace", "--flake", ".#user@wsl-ubuntu"},
		}}
		if !reflect.DeepEqual(calls, want) {
			t.Fatalf("calls = %+v, want %+v", calls, want)
		}
	})

	t.Run("dry-run on NixOS uses nixos-rebuild build without sudo", func(t *testing.T) {
		var calls []recordedCall
		e := testEnv(&calls)
		e.fileExists = func(path string) bool { return path == nixosMarkerPath }

		if err := run([]string{"apply", "--dry-run"}, e); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		want := []recordedCall{{
			name: "nixos-rebuild",
			args: []string{"build", "--flake", ".#moss", "--show-trace"},
		}}
		if !reflect.DeepEqual(calls, want) {
			t.Fatalf("calls = %+v, want %+v", calls, want)
		}
	})

	t.Run("dry-run on home-manager passes -n flag", func(t *testing.T) {
		var calls []recordedCall
		e := testEnv(&calls)
		e.hostname = func() (string, error) { return "lima", nil }

		if err := run([]string{"apply", "--dry-run"}, e); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		want := []recordedCall{{
			name: "nix",
			args: []string{"run", ".#home-manager", "--", "switch", "-n", "-b", "backup", "--show-trace", "--flake", ".#user@lima"},
		}}
		if !reflect.DeepEqual(calls, want) {
			t.Fatalf("calls = %+v, want %+v", calls, want)
		}
	})

	t.Run("rejects extra arguments", func(t *testing.T) {
		var calls []recordedCall
		if err := run([]string{"apply", "moss"}, testEnv(&calls)); err == nil {
			t.Fatal("expected error for extra args, got nil")
		}
	})
}

func TestRunNixos(t *testing.T) {
	t.Run("falls back to fzf when hostname is not in flake", func(t *testing.T) {
		var calls []recordedCall
		e := testEnv(&calls)
		e.hostname = func() (string, error) { return "unknown-host", nil }
		e.selectItem = func(items []string, prompt, header string) (string, error) {
			if !strings.Contains(header, "unknown-host") {
				t.Errorf("expected header to mention hostname, got %q", header)
			}
			return "algae", nil
		}

		if err := run([]string{"nixos"}, e); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		want := []recordedCall{{
			name: "sudo",
			args: []string{"nixos-rebuild", "switch", "--flake", ".#algae", "--show-trace"},
		}}
		if !reflect.DeepEqual(calls, want) {
			t.Fatalf("calls = %+v, want %+v", calls, want)
		}
	})

	t.Run("returns nil when fzf selection is canceled", func(t *testing.T) {
		var calls []recordedCall
		e := testEnv(&calls)
		e.hostname = func() (string, error) { return "unknown-host", nil }
		e.selectItem = func(items []string, prompt, header string) (string, error) {
			return "", errSelectionCanceled
		}

		if err := run([]string{"nixos"}, e); err != nil {
			t.Fatalf("unexpected error on cancel: %v", err)
		}
		if len(calls) != 0 {
			t.Fatalf("expected no commands on cancel, got %+v", calls)
		}
	})

	t.Run("fails closed in non-interactive shell when hostname does not match", func(t *testing.T) {
		var calls []recordedCall
		e := testEnv(&calls)
		e.hostname = func() (string, error) { return "unknown-host", nil }
		e.isTerminal = func() bool { return false }

		err := run([]string{"nixos"}, e)
		if err == nil || !strings.Contains(err.Error(), "non-interactive") {
			t.Fatalf("expected non-interactive error, got %v", err)
		}
	})
}

func TestRunHomeManager(t *testing.T) {
	t.Run("auto-detects exact user@host match without fzf", func(t *testing.T) {
		var calls []recordedCall
		e := testEnv(&calls)
		e.hostname = func() (string, error) { return "lima", nil }
		e.selectItem = func(items []string, prompt, header string) (string, error) {
			t.Fatal("selectItem should not be called when user@host matches")
			return "", nil
		}

		if err := run([]string{"home-manager"}, e); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		want := []recordedCall{{
			name: "nix",
			args: []string{"run", ".#home-manager", "--", "switch", "-b", "backup", "--show-trace", "--flake", ".#user@lima"},
		}}
		if !reflect.DeepEqual(calls, want) {
			t.Fatalf("calls = %+v, want %+v", calls, want)
		}
	})

	t.Run("rejects extra arguments", func(t *testing.T) {
		var calls []recordedCall
		if err := run([]string{"home-manager", "wsl-ubuntu"}, testEnv(&calls)); err == nil {
			t.Fatal("expected error for extra args, got nil")
		}
	})
}

func TestRunUpdate(t *testing.T) {
	t.Run("commits when flake files changed", func(t *testing.T) {
		var calls []recordedCall
		e := testEnv(&calls)
		e.cmdExitOK = func(name string, args ...string) (bool, error) {
			return false, nil
		}

		if err := run([]string{"update"}, e); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		want := []recordedCall{
			{name: "nix", args: []string{"flake", "update"}},
			{name: "nix", args: []string{"run", ".#dedup-flake-inputs"}},
			{name: "git", args: []string{"commit", "--no-gpg-sign", "-m", "flake.lock: Update", "flake.nix", "flake.lock"}},
			{name: "nix", args: []string{"run", ".#bump_gomod", "--", ".", "cmd/winit-reg"}},
		}
		if !reflect.DeepEqual(calls, want) {
			t.Fatalf("calls = %+v, want %+v", calls, want)
		}
	})

	t.Run("skips commit when flake files are unchanged", func(t *testing.T) {
		var calls []recordedCall
		e := testEnv(&calls)
		e.cmdExitOK = func(name string, args ...string) (bool, error) {
			return true, nil
		}

		if err := run([]string{"update"}, e); err != nil {
			t.Fatalf("unexpected error: %v", err)
		}

		want := []recordedCall{
			{name: "nix", args: []string{"flake", "update"}},
			{name: "nix", args: []string{"run", ".#dedup-flake-inputs"}},
			{name: "nix", args: []string{"run", ".#bump_gomod", "--", ".", "cmd/winit-reg"}},
		}
		if !reflect.DeepEqual(calls, want) {
			t.Fatalf("calls = %+v, want %+v", calls, want)
		}
	})
}

func TestFetchGHCRUTCTags(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/token":
			_ = json.NewEncoder(w).Encode(map[string]string{"token": "secret-token"})
		case "/tags":
			if got := r.Header.Get("Authorization"); got != "Bearer secret-token" {
				http.Error(w, "missing bearer token", http.StatusUnauthorized)
				return
			}
			_ = json.NewEncoder(w).Encode(map[string][]string{
				"tags": {"latest", "20260101-utc", "staging", "20260201-utc"},
			})
		default:
			http.NotFound(w, r)
		}
	}))
	defer srv.Close()

	got, err := fetchGHCRUTCTags(context.Background(), srv.Client(), srv.URL+"/token", srv.URL+"/tags")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	want := []string{"20260201-utc", "20260101-utc"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("tags = %v, want %v", got, want)
	}
}

func TestSelectWithFzf(t *testing.T) {
	binDir := t.TempDir()
	argsFile := filepath.Join(binDir, "args.txt")
	stdinFile := filepath.Join(binDir, "stdin.txt")
	fakeFzf := filepath.Join(binDir, "fzf")
	script := "#!/bin/sh\nprintf '%s\\n' \"$@\" > \"" + argsFile + "\"\ncat > \"" + stdinFile + "\"\nhead -n 1 \"" + stdinFile + "\"\n"
	if err := os.WriteFile(fakeFzf, []byte(script), 0o755); err != nil {
		t.Fatal(err)
	}

	t.Setenv("PATH", binDir+string(os.PathListSeparator)+os.Getenv("PATH"))

	var stderr bytes.Buffer
	got, err := selectWithFzf([]string{"20260201-utc", "20260101-utc"}, "ghcr> ", "", &stderr)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "20260201-utc" {
		t.Fatalf("selected = %q, want %q", got, "20260201-utc")
	}

	rawArgs, err := os.ReadFile(argsFile)
	if err != nil {
		t.Fatal(err)
	}
	gotArgs := strings.Split(strings.TrimSuffix(string(rawArgs), "\n"), "\n")
	wantArgs := []string{"--prompt=ghcr> "}
	if !reflect.DeepEqual(gotArgs, wantArgs) {
		t.Fatalf("fzf args = %v, want %v", gotArgs, wantArgs)
	}

	rawStdin, err := os.ReadFile(stdinFile)
	if err != nil {
		t.Fatal(err)
	}
	wantStdin := "20260201-utc\n20260101-utc\n"
	if string(rawStdin) != wantStdin {
		t.Fatalf("fzf stdin = %q, want %q", string(rawStdin), wantStdin)
	}
}

func TestRunUnknownSubcommand(t *testing.T) {
	var calls []recordedCall
	err := run([]string{"nope"}, testEnv(&calls))
	if err == nil || !strings.Contains(err.Error(), "unknown subcommand") {
		t.Fatalf("expected unknown subcommand error, got %v", err)
	}
}

func TestRunGHCRWithEndpointsAndCache(t *testing.T) {
	const (
		shaMain  = "1111111111111111111111111111111111111111"
		shaPR    = "2222222222222222222222222222222222222222"
		digMain  = "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
		digPR    = "sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
		digStale = "sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
		tagMain  = "20261126-000000-utc"
		tagPR    = "20261125-000000-utc"
	)

	var manifestHits atomic.Int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/token":
			_ = json.NewEncoder(w).Encode(map[string]string{"token": "pull-token"})
		case "/manifests/" + digMain:
			manifestHits.Add(1)
			_ = json.NewEncoder(w).Encode(map[string]any{
				"config": map[string]any{"size": 1024},
				"layers": []map[string]any{
					{"digest": "sha256:11111111111111111111", "size": 100 * 1024 * 1024},
					{"digest": "sha256:22222222222222222222", "size": 50 * 1024 * 1024},
				},
			})
		case "/manifests/" + digPR:
			manifestHits.Add(1)
			_ = json.NewEncoder(w).Encode(map[string]any{
				"config": map[string]any{"size": 512},
				"layers": []map[string]any{
					{"digest": "sha256:33333333333333333333", "size": 200 * 1024 * 1024},
				},
			})
		default:
			http.NotFound(w, r)
		}
	}))
	defer srv.Close()

	cacheRoot := t.TempDir()
	cachePath := filepath.Join(cacheRoot, "dot-task", "ghcr-manifests.json")
	if err := saveGHCRManifestCache(cachePath, ghcrManifestCache{
		Version: ghcrManifestCacheVersion,
		Manifests: map[string]cachedManifest{
			digStale: {TotalBytes: 123},
		},
	}); err != nil {
		t.Fatal(err)
	}

	versionsJSON := `[
		{
			"name": "` + digPR + `",
			"created_at": "2026-11-25T00:00:00Z",
			"metadata": {"container": {"tags": ["` + tagPR + `", "pr-42-` + shaPR + `"]}}
		},
		{
			"name": "` + digMain + `",
			"created_at": "2026-11-26T00:00:00Z",
			"metadata": {"container": {"tags": ["latest", "` + shaMain + `", "` + tagMain + `"]}}
		}
	]`

	var calls []recordedCall
	var capturedOpts fzfOptions
	var capturedRows []string
	e := testEnv(&calls)
	e.cacheDir = func() (string, error) { return cacheRoot, nil }
	e.executable = func() (string, error) { return "/usr/local/bin/dot-task", nil }
	e.now = func() time.Time { return time.Date(2026, 11, 26, 3, 0, 0, 0, time.UTC) }
	e.cmdCombinedOutput = func(name string, args ...string) ([]byte, error) {
		switch name {
		case "gh":
			return []byte(versionsJSON), nil
		case "podman":
			return []byte("ghcr.io/kachick/home:" + tagMain + "\t" + digMain + "\n"), nil
		case "git":
			return []byte(shaMain + "\tAdd new feature\n" + shaPR + "\tTest staging PR\n"), nil
		default:
			return nil, errors.New("unexpected command: " + name)
		}
	}
	e.selectItemWithOptions = func(items []string, opts fzfOptions) (string, error) {
		capturedRows = items
		capturedOpts = opts
		return items[0], nil
	}

	if err := runGHCRWithEndpoints(context.Background(), srv.Client(), srv.URL+"/token", srv.URL+"/tags", srv.URL+"/manifests/", e); err != nil {
		t.Fatalf("first run failed: %v", err)
	}

	if manifestHits.Load() != 2 {
		t.Fatalf("manifest hits = %d, want 2", manifestHits.Load())
	}
	if len(capturedRows) != 2 {
		t.Fatalf("rows = %d, want 2", len(capturedRows))
	}
	if !strings.Contains(capturedRows[0], "150.0 MiB") || !strings.Contains(capturedRows[0], "latest") || !strings.Contains(capturedRows[0], "Add new feature") || !strings.Contains(capturedRows[0], "●") {
		t.Fatalf("first row missing expected columns: %q", capturedRows[0])
	}
	if !strings.Contains(capturedRows[1], "200.0 MiB") || !strings.Contains(capturedRows[1], "PR #42") || !strings.Contains(capturedRows[1], "Test staging PR") {
		t.Fatalf("second row missing expected columns: %q", capturedRows[1])
	}
	if !strings.Contains(capturedOpts.preview, "ghcr-preview {1} {2} {3} {4}") {
		t.Fatalf("unexpected preview command: %q", capturedOpts.preview)
	}

	wantCalls := []recordedCall{{name: "./containers/sandbox.bash", args: []string{"--ghcr", tagMain}}}
	if !reflect.DeepEqual(calls, wantCalls) {
		t.Fatalf("calls = %+v, want %+v", calls, wantCalls)
	}

	// Stale digest should have been pruned from the cache.
	loaded := loadGHCRManifestCache(cachePath)
	if _, ok := loaded.Manifests[digStale]; ok {
		t.Fatalf("expected stale digest %s to be pruned", digStale)
	}

	// Second run should reuse cached manifest sizes without hitting the manifest endpoint.
	if err := runGHCRWithEndpoints(context.Background(), srv.Client(), srv.URL+"/token", srv.URL+"/tags", srv.URL+"/manifests/", e); err != nil {
		t.Fatalf("second run failed: %v", err)
	}
	if manifestHits.Load() != 2 {
		t.Fatalf("manifest hits after cached run = %d, want 2", manifestHits.Load())
	}
}

func TestRunGHCRFallbackOnMissingScope(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/token":
			_ = json.NewEncoder(w).Encode(map[string]string{"token": "pull-token"})
		case "/tags":
			_ = json.NewEncoder(w).Encode(map[string][]string{
				"tags": {"latest", "20261125-000000-utc", "20261126-000000-utc"},
			})
		default:
			http.NotFound(w, r)
		}
	}))
	defer srv.Close()

	var calls []recordedCall
	var stderr bytes.Buffer
	var capturedOpts fzfOptions
	e := testEnv(&calls)
	e.stderr = &stderr
	e.cacheDir = func() (string, error) { return t.TempDir(), nil }
	e.now = func() time.Time { return time.Date(2026, 11, 26, 2, 0, 0, 0, time.UTC) }
	e.cmdCombinedOutput = func(name string, args ...string) ([]byte, error) {
		if name == "gh" {
			return []byte("gh: HTTP 403: Your token has not been granted the required scopes (read:packages)"), errors.New("exit status 1")
		}
		return nil, errors.New("unavailable")
	}
	e.selectItemWithOptions = func(items []string, opts fzfOptions) (string, error) {
		capturedOpts = opts
		return items[0], nil
	}

	if err := runGHCRWithEndpoints(context.Background(), srv.Client(), srv.URL+"/token", srv.URL+"/tags", srv.URL+"/manifests/", e); err != nil {
		t.Fatalf("fallback run failed: %v", err)
	}

	if !strings.Contains(stderr.String(), "gh auth refresh --scopes read:packages") {
		t.Fatalf("expected stderr hint, got %q", stderr.String())
	}
	if !strings.Contains(capturedOpts.header, "gh auth refresh --scopes read:packages") {
		t.Fatalf("expected fzf header hint, got %q", capturedOpts.header)
	}
	wantCalls := []recordedCall{{name: "./containers/sandbox.bash", args: []string{"--ghcr", "20261126-000000-utc"}}}
	if !reflect.DeepEqual(calls, wantCalls) {
		t.Fatalf("calls = %+v, want %+v", calls, wantCalls)
	}
}

func TestRunGHCRPreview(t *testing.T) {
	cacheRoot := t.TempDir()
	digest := "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	cachePath := filepath.Join(cacheRoot, "dot-task", "ghcr-manifests.json")
	if err := saveGHCRManifestCache(cachePath, ghcrManifestCache{
		Version: ghcrManifestCacheVersion,
		Manifests: map[string]cachedManifest{
			digest: {
				TotalBytes: 120 * 1024 * 1024,
				Layers: []cachedLayer{
					{Digest: "sha256:11111111111111111111", Size: 100 * 1024 * 1024},
					{Digest: "sha256:22222222222222222222", Size: 20 * 1024 * 1024},
				},
			},
		},
	}); err != nil {
		t.Fatal(err)
	}

	var calls []recordedCall
	var stdout bytes.Buffer
	e := testEnv(&calls)
	e.stdout = &stdout
	e.cacheDir = func() (string, error) { return cacheRoot, nil }
	e.cmdCombinedOutput = func(name string, args ...string) ([]byte, error) {
		if name == "git" && len(args) > 0 && args[0] == "show" {
			return []byte("commit abcdef\n\n    Sample commit\n\n file.go | 2 +-\n"), nil
		}
		return nil, errors.New("unexpected command")
	}

	err := run([]string{"ghcr-preview", "20261126-000000-utc", digest, "1111111111111111111111111111111111111111", "latest,20261126-000000-utc"}, e)
	if err != nil {
		t.Fatalf("preview failed: %v", err)
	}

	out := stdout.String()
	for _, want := range []string{
		"Image:  ghcr.io/kachick/home:20261126-000000-utc",
		"Tags:   latest, 20261126-000000-utc",
		"Size:   120.0 MiB (2 layers, compressed)",
		"100.0 MiB",
		"Sample commit",
	} {
		if !strings.Contains(out, want) {
			t.Errorf("preview output missing %q:\n%s", want, out)
		}
	}
}

func TestFetchSingleGHCRManifestIndex(t *testing.T) {
	const (
		indexDigest = "sha256:index"
		amd64Digest = "sha256:amd64"
	)
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.URL.Path {
		case "/manifests/" + indexDigest:
			_ = json.NewEncoder(w).Encode(map[string]any{
				"manifests": []map[string]any{
					{"digest": "sha256:attestation", "platform": map[string]string{"os": "unknown", "architecture": "unknown"}},
					{"digest": amd64Digest, "platform": map[string]string{"os": "linux", "architecture": "amd64"}},
				},
			})
		case "/manifests/" + amd64Digest:
			_ = json.NewEncoder(w).Encode(map[string]any{
				"config": map[string]any{"size": 100},
				"layers": []map[string]any{
					{"digest": "sha256:layer1", "size": 900},
				},
			})
		default:
			http.NotFound(w, r)
		}
	}))
	defer srv.Close()

	got, err := fetchSingleGHCRManifest(context.Background(), srv.Client(), srv.URL+"/manifests/", "tok", indexDigest)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.TotalBytes != 1000 || len(got.Layers) != 1 {
		t.Fatalf("manifest = %+v, want total 1000 and 1 layer", got)
	}
}

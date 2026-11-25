package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"testing"
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

func TestRunUnknownSubcommand(t *testing.T) {
	var calls []recordedCall
	err := run([]string{"nope"}, testEnv(&calls))
	if err == nil || !strings.Contains(err.Error(), "unknown subcommand") {
		t.Fatalf("expected unknown subcommand error, got %v", err)
	}
}

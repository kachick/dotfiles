package main

import (
	"bytes"
	"errors"
	"flag"
	"io"
	"slices"
	"strings"
	"testing"
)

func TestResolveSproutTarget(t *testing.T) {
	tests := []struct {
		name        string
		spec        string
		defaultUser string
		wantOwner   string
		wantRepo    string
		wantErr     bool
	}{
		{
			name:        "short name with default user",
			spec:        "demo-app",
			defaultUser: "kachick",
			wantOwner:   "kachick",
			wantRepo:    "demo-app",
		},
		{
			name:        "short name with .git suffix",
			spec:        "demo-app.git",
			defaultUser: "kachick",
			wantOwner:   "kachick",
			wantRepo:    "demo-app",
		},
		{
			name:        "short name without default user",
			spec:        "demo-app",
			defaultUser: "",
			wantErr:     true,
		},
		{
			name:      "explicit owner and repo",
			spec:      "myorg/demo-app",
			wantOwner: "myorg",
			wantRepo:  "demo-app",
		},
		{
			name:    "empty spec",
			spec:    "",
			wantErr: true,
		},
		{
			name:    "flag-like name",
			spec:    "-evil",
			wantErr: true,
		},
		{
			name:    "parent traversal",
			spec:    "../evil",
			wantErr: true,
		},
		{
			name:    "too many segments",
			spec:    "github.com/kachick/demo-app",
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			owner, repo, err := resolveSproutTarget(tt.spec, tt.defaultUser)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("resolveSproutTarget(%q) succeeded (%s/%s), want error", tt.spec, owner, repo)
				}
				return
			}
			if err != nil {
				t.Fatalf("resolveSproutTarget(%q) unexpected error: %v", tt.spec, err)
			}
			if owner != tt.wantOwner || repo != tt.wantRepo {
				t.Errorf("got (%q, %q), want (%q, %q)", owner, repo, tt.wantOwner, tt.wantRepo)
			}
		})
	}
}

func TestRunSproutWithDeps(t *testing.T) {
	t.Run("runs create, get, and auto-merge in order and prints worktree path", func(t *testing.T) {
		var calls []string
		wantWT := "/tmp/repos/github.com/kachick/demo-app/main"

		deps := sproutDeps{
			readDefaultUser: func() (string, error) {
				return "kachick", nil
			},
			createRepo: func(fullName string, _ io.Writer) error {
				calls = append(calls, "create:"+fullName)
				return nil
			},
			getRepo: func(fullName string, _ io.Writer) (string, error) {
				calls = append(calls, "get:"+fullName)
				return wantWT, nil
			},
			enableAutoMerge: func(fullName, workDir string, _ io.Writer) error {
				calls = append(calls, "edit:"+fullName+"@"+workDir)
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runSproutWithDeps([]string{"demo-app"}, deps, &stdout, &stderr); err != nil {
			t.Fatalf("runSproutWithDeps failed: %v", err)
		}

		wantCalls := []string{
			"create:kachick/demo-app",
			"get:kachick/demo-app",
			"edit:kachick/demo-app@" + wantWT,
		}
		if !slices.Equal(calls, wantCalls) {
			t.Errorf("calls = %v, want %v", calls, wantCalls)
		}
		if got := strings.TrimSpace(stdout.String()); got != wantWT {
			t.Errorf("stdout = %q, want %q", got, wantWT)
		}
	})

	t.Run("stops before get when create fails", func(t *testing.T) {
		var calledGet, calledEdit bool
		deps := sproutDeps{
			readDefaultUser: func() (string, error) { return "kachick", nil },
			createRepo:      func(string, io.Writer) error { return errors.New("create failed") },
			getRepo: func(string, io.Writer) (string, error) {
				calledGet = true
				return "/tmp/wt", nil
			},
			enableAutoMerge: func(string, string, io.Writer) error {
				calledEdit = true
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runSproutWithDeps([]string{"demo-app"}, deps, &stdout, &stderr); err == nil {
			t.Fatal("expected error, got nil")
		}
		if calledGet || calledEdit {
			t.Errorf("unexpected downstream calls: get=%v edit=%v", calledGet, calledEdit)
		}
		if stdout.Len() != 0 {
			t.Errorf("expected empty stdout on failure, got %q", stdout.String())
		}
	})

	t.Run("stops before auto-merge when get fails", func(t *testing.T) {
		var calledEdit bool
		deps := sproutDeps{
			readDefaultUser: func() (string, error) { return "kachick", nil },
			createRepo:      func(string, io.Writer) error { return nil },
			getRepo:         func(string, io.Writer) (string, error) { return "", errors.New("get failed") },
			enableAutoMerge: func(string, string, io.Writer) error {
				calledEdit = true
				return nil
			},
		}

		var stdout, stderr bytes.Buffer
		if err := runSproutWithDeps([]string{"demo-app"}, deps, &stdout, &stderr); err == nil {
			t.Fatal("expected error, got nil")
		}
		if calledEdit {
			t.Error("enableAutoMerge should not run when get fails")
		}
		if stdout.Len() != 0 {
			t.Errorf("expected empty stdout on failure, got %q", stdout.String())
		}
	})

	t.Run("does not print worktree path when auto-merge fails", func(t *testing.T) {
		deps := sproutDeps{
			readDefaultUser: func() (string, error) { return "kachick", nil },
			createRepo:      func(string, io.Writer) error { return nil },
			getRepo:         func(string, io.Writer) (string, error) { return "/tmp/wt", nil },
			enableAutoMerge: func(string, string, io.Writer) error { return errors.New("edit failed") },
		}

		var stdout, stderr bytes.Buffer
		if err := runSproutWithDeps([]string{"demo-app"}, deps, &stdout, &stderr); err == nil {
			t.Fatal("expected error, got nil")
		}
		if stdout.Len() != 0 {
			t.Errorf("expected empty stdout on failure, got %q", stdout.String())
		}
	})

	t.Run("help flag returns ErrHelp and missing args fail", func(t *testing.T) {
		var stdout, stderr bytes.Buffer
		if err := runSprout([]string{"--help"}, &stdout, &stderr); !errors.Is(err, flag.ErrHelp) {
			t.Fatalf("expected flag.ErrHelp, got %v", err)
		}

		stderr.Reset()
		if err := runSprout(nil, &stdout, &stderr); err == nil {
			t.Fatal("expected error for missing repository argument, got nil")
		}
	})
}

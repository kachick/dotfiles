package main

import (
	"bytes"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestResolveRepoSpec(t *testing.T) {
	tests := []struct {
		name        string
		spec        string
		defaultUser string
		wantHost    string
		wantOwner   string
		wantRepo    string
		wantURL     string
		wantErr     bool
	}{
		{
			name:        "short name with default user",
			spec:        "dotfiles",
			defaultUser: "kachick",
			wantHost:    "github.com",
			wantOwner:   "kachick",
			wantRepo:    "dotfiles",
			wantURL:     "https://github.com/kachick/dotfiles.git",
		},
		{
			name:        "short name without default user",
			spec:        "dotfiles",
			defaultUser: "",
			wantErr:     true,
		},
		{
			name:      "owner and repo",
			spec:      "kachick/dotfiles",
			wantHost:  "github.com",
			wantOwner: "kachick",
			wantRepo:  "dotfiles",
			wantURL:   "https://github.com/kachick/dotfiles.git",
		},
		{
			name:      "host owner and repo",
			spec:      "gitlab.com/owner/repo",
			wantHost:  "gitlab.com",
			wantOwner: "owner",
			wantRepo:  "repo",
			wantURL:   "https://gitlab.com/owner/repo.git",
		},
		{
			name:      "https URL without suffix",
			spec:      "https://github.com/kachick/dotfiles",
			wantHost:  "github.com",
			wantOwner: "kachick",
			wantRepo:  "dotfiles",
			wantURL:   "https://github.com/kachick/dotfiles.git",
		},
		{
			name:      "https URL with .git suffix",
			spec:      "https://github.com/kachick/dotfiles.git",
			wantHost:  "github.com",
			wantOwner: "kachick",
			wantRepo:  "dotfiles",
			wantURL:   "https://github.com/kachick/dotfiles.git",
		},
		{
			name:      "ssh URL preserved",
			spec:      "ssh://git@github.com/kachick/dotfiles.git",
			wantHost:  "github.com",
			wantOwner: "kachick",
			wantRepo:  "dotfiles",
			wantURL:   "ssh://git@github.com/kachick/dotfiles.git",
		},
		{
			name:      "git URL preserved",
			spec:      "git://github.com/kachick/dotfiles.git",
			wantHost:  "github.com",
			wantOwner: "kachick",
			wantRepo:  "dotfiles",
			wantURL:   "git://github.com/kachick/dotfiles.git",
		},
		{
			name:      "scp syntax with .git",
			spec:      "git@github.com:kachick/dotfiles.git",
			wantHost:  "github.com",
			wantOwner: "kachick",
			wantRepo:  "dotfiles",
			wantURL:   "git@github.com:kachick/dotfiles.git",
		},
		{
			name:      "scp syntax without .git",
			spec:      "git@github.com:kachick/dotfiles",
			wantHost:  "github.com",
			wantOwner: "kachick",
			wantRepo:  "dotfiles",
			wantURL:   "git@github.com:kachick/dotfiles.git",
		},
		{
			name:    "empty spec",
			spec:    "",
			wantErr: true,
		},
		{
			name:    "parent traversal two segments",
			spec:    "../evil",
			wantErr: true,
		},
		{
			name:    "parent traversal three segments",
			spec:    "../owner/repo",
			wantErr: true,
		},
		{
			name:    "too many segments",
			spec:    "a/b/c/d",
			wantErr: true,
		},
		{
			name:    "unsupported scheme",
			spec:    "ftp://github.com/kachick/dotfiles",
			wantErr: true,
		},
		{
			name:    "colon without user",
			spec:    "github.com:kachick/dotfiles",
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			host, owner, repo, cloneURL, err := resolveRepoSpec(tt.spec, tt.defaultUser)
			if tt.wantErr {
				if err == nil {
					t.Fatalf("resolveRepoSpec(%q) succeeded (%s/%s/%s, %s), want error", tt.spec, host, owner, repo, cloneURL)
				}
				return
			}
			if err != nil {
				t.Fatalf("resolveRepoSpec(%q) unexpected error: %v", tt.spec, err)
			}
			if host != tt.wantHost || owner != tt.wantOwner || repo != tt.wantRepo || cloneURL != tt.wantURL {
				t.Errorf("got (%q, %q, %q, %q), want (%q, %q, %q, %q)",
					host, owner, repo, cloneURL, tt.wantHost, tt.wantOwner, tt.wantRepo, tt.wantURL)
			}
		})
	}
}

func TestRunGet_LocalCloneAndRepeatRun(t *testing.T) {
	isolateEnv(t)

	repoRoot := t.TempDir()
	t.Setenv("GIT_X_ROOT", repoRoot)

	seedDir := setupInitSeedRepo(t, "trunk", true)
	missingSeed := filepath.Join(t.TempDir(), "missing")

	cfgPath := filepath.Join(t.TempDir(), "gitconfig")
	cfgContent := fmt.Sprintf(`[git-x]
	user = kachick
[url %q]
	insteadOf = https://github.com/kachick/dotfiles.git
[url %q]
	insteadOf = https://github.com/kachick/missing.git
`, seedDir, missingSeed)
	writeTestFile(t, cfgPath, cfgContent)
	t.Setenv("GIT_CONFIG_GLOBAL", cfgPath)

	var stdout, stderr bytes.Buffer
	if err := runGet([]string{"dotfiles"}, &stdout, &stderr); err != nil {
		t.Fatalf("first runGet failed: %v, stderr: %s", err, stderr.String())
	}

	repoDir := filepath.Join(repoRoot, "github.com", "kachick", "dotfiles")
	wantWT := filepath.Join(repoDir, "trunk")
	if got := strings.TrimSpace(stdout.String()); got != wantWT {
		t.Fatalf("stdout = %q, want %q", got, wantWT)
	}

	isBare := runGit(t, repoDir, "rev-parse", "--is-bare-repository")
	if isBare != "true" {
		t.Errorf("is-bare-repository = %q, want true", isBare)
	}

	fetchSpec := runGit(t, repoDir, "config", "--get", "remote.origin.fetch")
	if fetchSpec != "+refs/heads/*:refs/remotes/origin/*" {
		t.Errorf("remote.origin.fetch = %q", fetchSpec)
	}

	if state := direnvAllowedState(t, wantWT); state == 0 {
		t.Fatalf("expected .envrc NOT to be allowed without --trust, got state=%d", state)
	}

	// Repeat run on already-cloned repository should succeed and apply --trust.
	stdout.Reset()
	stderr.Reset()
	if err := runGet([]string{"--trust", "kachick/dotfiles"}, &stdout, &stderr); err != nil {
		t.Fatalf("second runGet failed: %v, stderr: %s", err, stderr.String())
	}
	if got := strings.TrimSpace(stdout.String()); got != wantWT {
		t.Errorf("second stdout = %q, want %q", got, wantWT)
	}
	if state := direnvAllowedState(t, wantWT); state != 0 {
		t.Fatalf("expected .envrc to be allowed with --trust, got state=%d", state)
	}

	// Failed clone should remove empty repoDir cleanly.
	stdout.Reset()
	stderr.Reset()
	if err := runGet([]string{"kachick/missing"}, &stdout, &stderr); err == nil {
		t.Fatal("expected runGet on missing remote to fail, got nil")
	}
	missingRepoDir := filepath.Join(repoRoot, "github.com", "kachick", "missing")
	if _, err := os.Stat(missingRepoDir); !os.IsNotExist(err) {
		t.Errorf("expected failed clone directory %s to be removed, stat err = %v", missingRepoDir, err)
	}
}

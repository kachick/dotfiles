package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

func validateRepoPart(label, value string) error {
	if value == "" || value == "." || value == ".." {
		return fmt.Errorf("invalid %s: %q", label, value)
	}
	if strings.Contains(value, "..") || strings.ContainsAny(value, `/\:`+" \t\r\n") {
		return fmt.Errorf("invalid %s: %q", label, value)
	}
	return nil
}

func validateRepoParts(host, owner, repo string) error {
	if err := validateRepoPart("host", host); err != nil {
		return err
	}
	if strings.HasPrefix(host, ".") || strings.HasSuffix(host, ".") {
		return fmt.Errorf("invalid host: %q", host)
	}
	if err := validateRepoPart("owner", owner); err != nil {
		return err
	}
	if err := validateRepoPart("repo", repo); err != nil {
		return err
	}
	return nil
}

func splitOwnerRepoPath(rawPath string) (owner, repo string, err error) {
	trimmed := strings.Trim(rawPath, "/")
	trimmed = strings.TrimSuffix(trimmed, ".git")
	parts := strings.Split(trimmed, "/")
	if len(parts) != 2 {
		return "", "", fmt.Errorf("expected owner/repo path, got %q", rawPath)
	}
	return parts[0], parts[1], nil
}

func resolveRepoSpec(spec, defaultUser string) (host, owner, repo, cloneURL string, err error) {
	spec = strings.TrimSpace(spec)
	if spec == "" {
		return "", "", "", "", errors.New("repository spec cannot be empty")
	}

	if strings.Contains(spec, "://") {
		u, err := url.Parse(spec)
		if err != nil {
			return "", "", "", "", fmt.Errorf("parse repository URL %q: %w", spec, err)
		}
		switch u.Scheme {
		case "http", "https", "ssh", "git":
		default:
			return "", "", "", "", fmt.Errorf("unsupported repository URL scheme %q", u.Scheme)
		}
		host = u.Hostname()
		owner, repo, err = splitOwnerRepoPath(u.Path)
		if err != nil {
			return "", "", "", "", fmt.Errorf("invalid repository URL %q: %w", spec, err)
		}
		if err := validateRepoParts(host, owner, repo); err != nil {
			return "", "", "", "", err
		}
		if u.Scheme == "ssh" || u.Scheme == "git" {
			cloneURL = spec
		} else {
			cloneURL = fmt.Sprintf("https://%s/%s/%s.git", host, owner, repo)
		}
		return host, owner, repo, cloneURL, nil
	}

	if atIdx := strings.Index(spec, "@"); atIdx >= 0 {
		user := spec[:atIdx]
		rest := spec[atIdx+1:]
		hostPart, repoPath, hasColon := strings.Cut(rest, ":")
		if !hasColon {
			return "", "", "", "", fmt.Errorf("invalid SCP repository spec %q", spec)
		}
		if err := validateRepoPart("user", user); err != nil {
			return "", "", "", "", err
		}
		owner, repo, err = splitOwnerRepoPath(repoPath)
		if err != nil {
			return "", "", "", "", fmt.Errorf("invalid SCP repository spec %q: %w", spec, err)
		}
		if err := validateRepoParts(hostPart, owner, repo); err != nil {
			return "", "", "", "", err
		}
		cloneURL = fmt.Sprintf("%s@%s:%s/%s.git", user, hostPart, owner, repo)
		return hostPart, owner, repo, cloneURL, nil
	}

	if strings.Contains(spec, ":") {
		return "", "", "", "", fmt.Errorf("invalid repository spec %q", spec)
	}

	trimmed := strings.TrimSuffix(spec, "/")
	segments := strings.Split(trimmed, "/")
	switch len(segments) {
	case 3:
		host = segments[0]
		owner = segments[1]
		repo = strings.TrimSuffix(segments[2], ".git")
		if !strings.Contains(host, ".") {
			return "", "", "", "", fmt.Errorf("invalid host in repository spec %q", spec)
		}
		if err := validateRepoParts(host, owner, repo); err != nil {
			return "", "", "", "", err
		}
		cloneURL = fmt.Sprintf("https://%s/%s/%s.git", host, owner, repo)
		return host, owner, repo, cloneURL, nil
	case 2:
		host = "github.com"
		owner = segments[0]
		repo = strings.TrimSuffix(segments[1], ".git")
		if err := validateRepoParts(host, owner, repo); err != nil {
			return "", "", "", "", err
		}
		cloneURL = fmt.Sprintf("https://github.com/%s/%s.git", owner, repo)
		return host, owner, repo, cloneURL, nil
	case 1:
		repo = strings.TrimSuffix(segments[0], ".git")
		if err := validateRepoPart("repo", repo); err != nil {
			return "", "", "", "", err
		}
		if defaultUser == "" {
			return "", "", "", "", fmt.Errorf("cannot resolve short repository name %q without git config git-x.user", spec)
		}
		host = "github.com"
		owner = defaultUser
		if err := validateRepoParts(host, owner, repo); err != nil {
			return "", "", "", "", err
		}
		cloneURL = fmt.Sprintf("https://github.com/%s/%s.git", owner, repo)
		return host, owner, repo, cloneURL, nil
	default:
		return "", "", "", "", fmt.Errorf("invalid repository spec %q", spec)
	}
}

func readDefaultRepoUser() (string, error) {
	cmd := gitcmd.NewIsolated(os.TempDir(), io.Discard, io.Discard).Command("config", "--get", "git-x.user")
	out, err := cmd.Output()
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) && exitErr.ExitCode() == 1 {
			return "", nil
		}
		return "", fmt.Errorf("git config --get git-x.user: %w", err)
	}
	return strings.TrimSpace(string(out)), nil
}

func newGetFlagSet(stderr io.Writer) (*flag.FlagSet, *bool) {
	fs := flag.NewFlagSet("git-x get", flag.ContinueOnError)
	fs.SetOutput(stderr)
	trust := fs.Bool("trust", false, "run direnv allow if .envrc exists in the target worktree")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git x get [--trust] <repo_spec>\n\n")
		fmt.Fprintf(stderr, "Clone a repository into the clean-bare layout and print its default worktree path.\n\n")
		fs.PrintDefaults()
	}
	return fs, trust
}

func runGet(args []string, stdout, stderr io.Writer) error {
	fs, trust := newGetFlagSet(stderr)

	if err := fs.Parse(args); err != nil {
		return err
	}

	remaining := fs.Args()
	if len(remaining) != 1 {
		fs.Usage()
		return fmt.Errorf("expected 1 repository spec argument, got %d", len(remaining))
	}

	defaultUser, err := readDefaultRepoUser()
	if err != nil {
		return err
	}

	host, owner, repo, cloneURL, err := resolveRepoSpec(remaining[0], defaultUser)
	if err != nil {
		return err
	}

	roots, err := resolveRepoRoots()
	if err != nil {
		return err
	}
	if len(roots) == 0 {
		return errors.New("no repository root directories resolved")
	}

	repoDir := filepath.Join(roots[0], host, owner, repo)
	gitDir := filepath.Join(repoDir, ".git")
	if _, err := os.Stat(gitDir); err != nil {
		if !os.IsNotExist(err) {
			return err
		}
		if err := os.MkdirAll(repoDir, 0o755); err != nil {
			return fmt.Errorf("create repository directory %s: %w", repoDir, err)
		}
		// Route git output to stderr so stdout only emits the final worktree path.
		r := gitcmd.NewIsolated("", stderr, stderr)
		if err := r.Stream("clone", "--bare", cloneURL, gitDir); err != nil {
			_ = os.Remove(repoDir)
			return err
		}
	}

	return initCleanBare(repoDir, *trust, stdout, stderr)
}

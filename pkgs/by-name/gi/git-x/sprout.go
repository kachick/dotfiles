package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"

	"github.com/kachick/dotfiles/internal/gitcmd"
)

const (
	sproutTemplateRepo = "kachick/anylang-template"
	sproutDescription  = "🚧"
)

type sproutDeps struct {
	readDefaultUser func() (string, error)
	createRepo      func(fullName string, stderr io.Writer) error
	getRepo         func(fullName string, stderr io.Writer) (string, error)
	enableAutoMerge func(fullName, workDir string, stderr io.Writer) error
}

func (d sproutDeps) withDefaults() sproutDeps {
	if d.readDefaultUser == nil {
		d.readDefaultUser = readDefaultRepoUser
	}
	if d.createRepo == nil {
		d.createRepo = runGHRepoCreate
	}
	if d.getRepo == nil {
		d.getRepo = runSproutGet
	}
	if d.enableAutoMerge == nil {
		d.enableAutoMerge = runGHEnableAutoMerge
	}
	return d
}

func resolveSproutTarget(spec, defaultUser string) (owner, repo string, err error) {
	spec = strings.TrimSpace(spec)
	if spec == "" || strings.HasPrefix(spec, "-") {
		return "", "", fmt.Errorf("invalid repository name: %q", spec)
	}

	parts := strings.Split(spec, "/")
	switch len(parts) {
	case 1:
		repo = strings.TrimSuffix(parts[0], ".git")
		if err := validateRepoPart("repo", repo); err != nil {
			return "", "", err
		}
		if defaultUser == "" {
			return "", "", fmt.Errorf("cannot resolve short repository name %q without git config git-x.user", spec)
		}
		owner = defaultUser
	case 2:
		owner = parts[0]
		repo = strings.TrimSuffix(parts[1], ".git")
	default:
		return "", "", fmt.Errorf("expected <repo> or <owner>/<repo>, got %q", spec)
	}

	if err := validateRepoPart("owner", owner); err != nil {
		return "", "", err
	}
	if err := validateRepoPart("repo", repo); err != nil {
		return "", "", err
	}
	return owner, repo, nil
}

func runGHRepoCreate(fullName string, stderr io.Writer) error {
	cmd := exec.Command(
		"gh", "repo", "create", fullName,
		"--private",
		"--template="+sproutTemplateRepo,
		"--description="+sproutDescription,
	)
	cmd.Env = gitcmd.IsolatedEnv(os.Environ())
	// Route gh stdout to stderr so stdout only emits the final worktree path.
	cmd.Stdout = stderr
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("gh repo create %s: %w", fullName, err)
	}
	return nil
}

func runSproutGet(fullName string, stderr io.Writer) (string, error) {
	var out bytes.Buffer
	if err := runGet([]string{"--trust", fullName}, &out, stderr); err != nil {
		return "", err
	}
	wtDir := strings.TrimSpace(out.String())
	if wtDir == "" {
		return "", fmt.Errorf("git-x get %s returned empty worktree path", fullName)
	}
	return wtDir, nil
}

func runGHEnableAutoMerge(fullName, workDir string, stderr io.Writer) error {
	cmd := exec.Command("gh", "repo", "edit", fullName, "--enable-auto-merge")
	if workDir != "" {
		cmd.Dir = workDir
	}
	cmd.Env = gitcmd.IsolatedEnv(os.Environ())
	cmd.Stdout = stderr
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("gh repo edit %s --enable-auto-merge: %w", fullName, err)
	}
	return nil
}

func newSproutFlagSet(stderr io.Writer) *flag.FlagSet {
	fs := flag.NewFlagSet("git-x sprout", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: git x sprout <repo>\n\n")
		fmt.Fprintf(stderr, "Create a private GitHub repository from %s, clone it in clean-bare layout, enable auto-merge, and print its worktree path.\n", sproutTemplateRepo)
	}
	return fs
}

func runSprout(args []string, stdout, stderr io.Writer) error {
	return runSproutWithDeps(args, sproutDeps{}, stdout, stderr)
}

func runSproutWithDeps(args []string, deps sproutDeps, stdout, stderr io.Writer) error {
	deps = deps.withDefaults()
	fs := newSproutFlagSet(stderr)
	if err := fs.Parse(args); err != nil {
		return err
	}

	remaining := fs.Args()
	if len(remaining) != 1 {
		fs.Usage()
		return fmt.Errorf("expected 1 repository argument, got %d", len(remaining))
	}

	defaultUser, err := deps.readDefaultUser()
	if err != nil {
		return err
	}

	owner, repo, err := resolveSproutTarget(remaining[0], defaultUser)
	if err != nil {
		return err
	}
	fullName := owner + "/" + repo

	if err := deps.createRepo(fullName, stderr); err != nil {
		return err
	}

	wtDir, err := deps.getRepo(fullName, stderr)
	if err != nil {
		return err
	}

	if err := deps.enableAutoMerge(fullName, wtDir, stderr); err != nil {
		return err
	}

	fmt.Fprintln(stdout, wtDir)
	return nil
}

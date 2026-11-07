package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type changeResult struct {
	Packages    bool
	HomeManager bool
	Nixos       bool
	FlakeLock   bool
}

func (r changeResult) formatGitHubOutputs() string {
	return fmt.Sprintf(
		"packages=%t\nhome-manager=%t\nnixos=%t\nflake-lock=%t\n",
		r.Packages,
		r.HomeManager,
		r.Nixos,
		r.FlakeLock,
	)
}

func classifyChanges(eventName string, changedFiles []string) changeResult {
	if (eventName != "push" && eventName != "pull_request") || len(changedFiles) == 0 {
		return changeResult{
			Packages:    true,
			HomeManager: true,
			Nixos:       true,
			FlakeLock:   false,
		}
	}

	var res changeResult
	for _, rawPath := range changedFiles {
		p := strings.TrimSpace(filepath.ToSlash(rawPath))
		if p == "" {
			continue
		}

		if eventName == "pull_request" && p == "flake.lock" {
			res.FlakeLock = true
		}

		if isCoreNixCIPath(p) {
			res.Packages = true
			res.HomeManager = true
			res.Nixos = true
			continue
		}

		if strings.HasPrefix(p, "nixos/") {
			res.Nixos = true
		}

		if isPackageInputPath(p) {
			res.Packages = true
			res.HomeManager = true
		}

		if strings.HasPrefix(p, "home-manager/") {
			res.HomeManager = true
		}
	}

	return res
}

func isCoreNixCIPath(p string) bool {
	if p == "flake.nix" || p == "flake.lock" || p == ".github/workflows/nix.yml" {
		return true
	}
	if strings.HasPrefix(p, "overlays/") || strings.HasPrefix(p, ".github/actions/") {
		return true
	}
	return false
}

func isPackageInputPath(p string) bool {
	if p == "go.mod" || p == "go.sum" || p == "typos.toml" {
		return true
	}
	for _, prefix := range []string{"pkgs/", "config/", "internal/", "cmd/ci-build/"} {
		if strings.HasPrefix(p, prefix) {
			return true
		}
	}
	return false
}

func runChanges(args []string, stdout io.Writer) error {
	fs := flag.NewFlagSet("changes", flag.ExitOnError)
	eventFlag := fs.String("event", "", "GitHub event name (defaults to EVENT_NAME or GITHUB_EVENT_NAME)")
	baseFlag := fs.String("base", "HEAD^1", "Base git revision for diff")
	headFlag := fs.String("head", "HEAD", "Head git revision for diff")
	if err := fs.Parse(args); err != nil {
		return err
	}

	eventName := *eventFlag
	if eventName == "" {
		eventName = os.Getenv("EVENT_NAME")
	}
	if eventName == "" {
		eventName = os.Getenv("GITHUB_EVENT_NAME")
	}

	var changedFiles []string
	if eventName == "push" || eventName == "pull_request" {
		out, err := exec.Command("git", "diff", "--name-only", *baseFlag, *headFlag).Output()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Warning: git diff %s %s failed (%v); falling back to running all jobs\n", *baseFlag, *headFlag, err)
		} else {
			for _, line := range strings.Split(string(out), "\n") {
				trimmed := strings.TrimSpace(line)
				if trimmed != "" {
					changedFiles = append(changedFiles, trimmed)
				}
			}
		}
	}

	res := classifyChanges(eventName, changedFiles)
	_, err := io.WriteString(stdout, res.formatGitHubOutputs())
	return err
}

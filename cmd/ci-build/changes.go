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
	Container   bool
	FlakeLock   bool
}

func (r changeResult) formatGitHubOutputs() string {
	return fmt.Sprintf(
		"packages=%t\nhome-manager=%t\nnixos=%t\ncontainer=%t\nflake-lock=%t\n",
		r.Packages,
		r.HomeManager,
		r.Nixos,
		r.Container,
		r.FlakeLock,
	)
}

func classifyChanges(eventName, target string, changedFiles []string) changeResult {
	if eventName == "workflow_dispatch" {
		switch target {
		case "packages":
			return changeResult{Packages: true}
		case "home-manager":
			return changeResult{HomeManager: true}
		case "nixos":
			return changeResult{Nixos: true}
		case "nixos-iso":
			return changeResult{}
		default:
			return changeResult{
				Packages:    true,
				HomeManager: true,
				Nixos:       true,
			}
		}
	}

	if (eventName != "push" && eventName != "pull_request") || len(changedFiles) == 0 {
		return changeResult{
			Packages:    true,
			HomeManager: true,
			Nixos:       true,
			Container:   eventName == "push",
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

		if eventName == "push" && isContainerInputPath(p) {
			res.Container = true
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

func isContainerInputPath(p string) bool {
	if strings.HasSuffix(p, ".md") {
		return false
	}
	switch p {
	case ".github/workflows/container.yml", "flake.nix", "flake.lock", "nixos/configuration.nix", "nixos/nix.nix":
		return true
	}
	for _, prefix := range []string{
		".github/actions/setup-nix/",
		"config/",
		"containers/",
		"home-manager/",
		"nixos/hosts/installer/",
		"nixos/modules/",
		"overlays/",
		"pkgs/",
	} {
		if strings.HasPrefix(p, prefix) {
			return true
		}
	}
	return false
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
	if p == "go.mod" || p == "typos.toml" {
		return true
	}
	for _, prefix := range []string{"pkgs/", "config/", "internal/", "cmd/ci-build/", "nixos/hosts/sandbox/"} {
		if strings.HasPrefix(p, prefix) {
			return true
		}
	}
	return false
}

func isZeroSHA(rev string) bool {
	return len(rev) >= 40 && strings.Trim(rev, "0") == ""
}

func runChanges(args []string, stdout io.Writer) error {
	fs := flag.NewFlagSet("changes", flag.ContinueOnError)
	eventFlag := fs.String("event", "", "GitHub event name (defaults to EVENT_NAME or GITHUB_EVENT_NAME)")
	targetFlag := fs.String("target", "", "Target job for workflow_dispatch (defaults to TARGET)")
	baseFlag := fs.String("base", "", "Base git revision for diff (defaults to BASE_SHA or HEAD^1)")
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

	target := *targetFlag
	if target == "" {
		target = os.Getenv("TARGET")
	}

	baseRev := strings.TrimSpace(*baseFlag)
	if baseRev == "" {
		baseRev = strings.TrimSpace(os.Getenv("BASE_SHA"))
	}
	if baseRev == "" {
		baseRev = "HEAD^1"
	}

	var changedFiles []string
	if (eventName == "push" || eventName == "pull_request") && !isZeroSHA(baseRev) {
		out, err := exec.Command("git", "diff", "--name-only", baseRev, *headFlag).Output()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Warning: git diff %s %s failed (%v); falling back to running all jobs\n", baseRev, *headFlag, err)
		} else {
			for _, line := range strings.Split(string(out), "\n") {
				trimmed := strings.TrimSpace(line)
				if trimmed != "" {
					changedFiles = append(changedFiles, trimmed)
				}
			}
		}
	}

	res := classifyChanges(eventName, target, changedFiles)
	_, err := io.WriteString(stdout, res.formatGitHubOutputs())
	return err
}

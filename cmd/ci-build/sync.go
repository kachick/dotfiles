package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
)

type PackageConfig struct {
	Build  bool `json:"build"`
	Test   bool `json:"test"`
	Update bool `json:"update"`
}

type PackagesFile struct {
	Packages map[string]PackageConfig `json:"packages"`
}

const (
	beginMarker = "# BEGIN MANAGED PACKAGES"
	endMarker   = "# END MANAGED PACKAGES"
)

func runSyncWorkflows(args []string) error {
	fs := flag.NewFlagSet("sync-workflows", flag.ExitOnError)
	checkOnly := fs.Bool("check", false, "Fail if workflows are out of sync without modifying files")
	if err := fs.Parse(args); err != nil {
		return err
	}

	repoRootBytes, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		return fmt.Errorf("failed to detect repository root: %w", err)
	}
	repoRoot := strings.TrimSpace(string(repoRootBytes))

	packagesPath := filepath.Join(repoRoot, "pkgs", "list.toml")
	packagesFile, err := loadPackagesConfig(packagesPath)
	if err != nil {
		return fmt.Errorf("loading pkgs/list.toml: %w", err)
	}

	// 1. Generate nix.yml parallel steps
	sortedNames := make([]string, 0, len(packagesFile.Packages))
	for name := range packagesFile.Packages {
		sortedNames = append(sortedNames, name)
	}
	sort.Strings(sortedNames)

	var packageLinuxEntries []string
	for _, name := range sortedNames {
		cfg := packagesFile.Packages[name]
		if !cfg.Build {
			continue
		}
		cmd := fmt.Sprintf("go run ./cmd/ci-build package %s", name)
		if !cfg.Test {
			cmd += " --skip-tests"
		}
		entry := fmt.Sprintf("          - name: %s\n            run: %s", name, cmd)
		packageLinuxEntries = append(packageLinuxEntries, entry)
	}
	packageLinuxBlock := strings.Join(packageLinuxEntries, "\n\n")

	// 2. Generate update-local-packages.yml matrix entries
	var updateEntries []string
	for _, name := range sortedNames {
		cfg := packagesFile.Packages[name]
		if !cfg.Update {
			continue
		}
		updateEntries = append(updateEntries, fmt.Sprintf("          - %s", name))
	}
	updateBlock := strings.Join(updateEntries, "\n")

	targets := []struct {
		relPath string
		content string
	}{
		{relPath: ".github/workflows/nix.yml", content: packageLinuxBlock},
		{relPath: ".github/workflows/update-local-packages.yml", content: updateBlock},
	}

	hasDiff := false
	for _, target := range targets {
		fullPath := filepath.Join(repoRoot, target.relPath)
		origBytes, err := os.ReadFile(fullPath)
		if err != nil {
			return fmt.Errorf("reading %s: %w", target.relPath, err)
		}
		orig := string(origBytes)

		updated, err := replaceMarkedBlock(orig, target.content)
		if err != nil {
			return fmt.Errorf("updating %s: %w", target.relPath, err)
		}

		if orig != updated {
			hasDiff = true
			if *checkOnly {
				fmt.Fprintf(os.Stderr, "%s is out of sync with pkgs/list.toml\n", target.relPath)
			} else {
				if err := os.WriteFile(fullPath, []byte(updated), 0o644); err != nil {
					return fmt.Errorf("writing %s: %w", target.relPath, err)
				}
				fmt.Printf("Updated %s\n", target.relPath)
			}
		}
	}

	if *checkOnly && hasDiff {
		return fmt.Errorf("workflows are not synchronized with pkgs/list.toml. Run 'go run ./cmd/ci-build sync-workflows' to update them")
	}

	if !hasDiff {
		fmt.Println("All workflows are up to date.")
	}

	return verifyUpdateScripts(repoRoot)
}

func verifyUpdateScripts(repoRoot string) error {
	expr := `
let
  flake = builtins.getFlake (toString ./.);
  system = builtins.currentSystem;
  pkgs = flake.packages.${system};
  config = builtins.fromTOML (builtins.readFile ./pkgs/list.toml);
  lib = flake.inputs.nixpkgs.lib;

  updatePkgs = lib.filterAttrs (_: cfg: cfg.update or false) config.packages;

  checkPkg = name: _:
    let
      pkg = pkgs.${name} or null;
      script = if pkg != null then (pkg.passthru.updateScript or pkg.updateScript or null) else null;
    in
    if builtins.isList script && builtins.any (arg: lib.hasSuffix "/bin/nix-update" (toString arg)) script then
      if builtins.elem "--flake" script then
        null
      else
        "${name}: updateScript uses nix-update-script but is missing \"--flake\" in extraArgs"
    else
      null;

  errors = lib.filter (e: e != null) (lib.mapAttrsToList checkPkg updatePkgs);
in
errors
`
	cmd := exec.Command("nix", "eval", "--impure", "--json", "--expr", expr)
	cmd.Dir = repoRoot
	out, err := cmd.Output()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			return fmt.Errorf("evaluating updateScripts via nix: %s: %w", string(exitErr.Stderr), err)
		}
		return fmt.Errorf("evaluating updateScripts via nix: %w", err)
	}

	var errList []string
	if err := json.Unmarshal(out, &errList); err != nil {
		return fmt.Errorf("unmarshaling updateScripts eval result: %w", err)
	}

	if len(errList) > 0 {
		return fmt.Errorf("updateScript validation failed:\n  %s", strings.Join(errList, "\n  "))
	}

	return nil
}

func loadPackagesConfig(path string) (*PackagesFile, error) {
	// Use nix eval with builtins.fromTOML to avoid adding external dependencies to go.mod
	expr := fmt.Sprintf("builtins.fromTOML (builtins.readFile %s)", path)
	cmd := exec.Command("nix", "eval", "--impure", "--json", "--expr", expr)
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("evaluating %s via nix fromTOML: %w", path, err)
	}

	var pf PackagesFile
	if err := json.Unmarshal(out, &pf); err != nil {
		return nil, fmt.Errorf("unmarshaling JSON from %s: %w", path, err)
	}
	return &pf, nil
}

func replaceMarkedBlock(content, newBlock string) (string, error) {
	beginIdx := strings.Index(content, beginMarker)
	if beginIdx == -1 {
		return "", fmt.Errorf("marker %q not found", beginMarker)
	}
	endIdx := strings.Index(content, endMarker)
	if endIdx == -1 {
		return "", fmt.Errorf("marker %q not found", endMarker)
	}
	if beginIdx >= endIdx {
		return "", fmt.Errorf("invalid marker positions: begin %d, end %d", beginIdx, endIdx)
	}

	// Find the end of the line containing beginMarker
	beginLineEnd := strings.Index(content[beginIdx:], "\n")
	if beginLineEnd == -1 {
		return "", fmt.Errorf("malformed line after begin marker")
	}
	beginLineEnd += beginIdx + 1

	// Find the start of the line containing endMarker
	endLineStart := strings.LastIndex(content[:endIdx], "\n")
	if endLineStart == -1 {
		endLineStart = 0
	} else {
		endLineStart += 1
	}

	var sb strings.Builder
	sb.WriteString(content[:beginLineEnd])
	sb.WriteString(newBlock)
	sb.WriteString("\n")
	sb.WriteString(content[endLineStart:])

	return sb.String(), nil
}

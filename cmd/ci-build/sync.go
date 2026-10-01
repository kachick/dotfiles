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

	packagesPath := filepath.Join(repoRoot, "packages.toml")
	packagesFile, err := loadPackagesConfig(packagesPath)
	if err != nil {
		return fmt.Errorf("loading packages.toml: %w", err)
	}

	sortedNames := make([]string, 0, len(packagesFile.Packages))
	for name := range packagesFile.Packages {
		sortedNames = append(sortedNames, name)
	}
	sort.Strings(sortedNames)

	// Generate update-local-packages.yml matrix entries
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
				fmt.Fprintf(os.Stderr, "%s is out of sync with packages.toml\n", target.relPath)
			} else {
				if err := os.WriteFile(fullPath, []byte(updated), 0o644); err != nil {
					return fmt.Errorf("writing %s: %w", target.relPath, err)
				}
				fmt.Printf("Updated %s\n", target.relPath)
			}
		}
	}

	if *checkOnly && hasDiff {
		return fmt.Errorf("workflows are not synchronized with packages.toml. Run 'go run ./cmd/ci-build sync-workflows' to update them")
	}

	if !hasDiff {
		fmt.Println("All workflows are up to date.")
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

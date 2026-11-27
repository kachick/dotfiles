package repocheck

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
)

func RunAll(root string) error {
	return errors.Join(
		CheckWorkflowPaths(root),
		CheckGoAndDprintVersions(root),
		CheckByNamePrefixes(root),
	)
}

func CheckWorkflowPaths(root string) error {
	workflowPath := filepath.Join(root, ".github", "workflows", "nix.yml")
	out, err := exec.Command("yq", "--output-format=json", ".on", workflowPath).Output()
	if err != nil {
		return fmt.Errorf("running yq on %s: %w", workflowPath, err)
	}
	return checkWorkflowPathsJSON(out)
}

func checkWorkflowPathsJSON(data []byte) error {
	var on struct {
		Push struct {
			Paths []string `json:"paths"`
		} `json:"push"`
		PullRequest struct {
			Paths []string `json:"paths"`
		} `json:"pull_request"`
	}
	if err := json.Unmarshal(data, &on); err != nil {
		return fmt.Errorf("parsing nix.yml .on JSON: %w", err)
	}
	if len(on.Push.Paths) == 0 || len(on.PullRequest.Paths) == 0 {
		return errors.New("nix.yml on.push.paths and on.pull_request.paths must both be non-empty")
	}
	if !slices.Equal(on.Push.Paths, on.PullRequest.Paths) {
		return fmt.Errorf(
			"nix.yml on.push.paths and on.pull_request.paths differ:\n  push: %v\n  pull_request: %v",
			on.Push.Paths,
			on.PullRequest.Paths,
		)
	}
	return nil
}

type dprintConfig struct {
	Gofumpt struct {
		LangVersion string `json:"langVersion"`
	} `json:"gofumpt"`
	Plugins []string `json:"plugins"`
}

func CheckGoAndDprintVersions(root string) error {
	rootGoFull, rootGoMinor, err := parseGoModVersion(filepath.Join(root, "go.mod"))
	if err != nil {
		return err
	}

	var errs []error

	winitGoFull, _, err := parseGoModVersion(filepath.Join(root, "cmd", "winit-reg", "go.mod"))
	if err != nil {
		errs = append(errs, err)
	} else if winitGoFull != rootGoFull {
		errs = append(errs, fmt.Errorf("cmd/winit-reg/go.mod has go %s, want %s (from go.mod)", winitGoFull, rootGoFull))
	}

	rootDprint, err := loadDprintConfig(filepath.Join(root, "dprint.jsonc"))
	if err != nil {
		errs = append(errs, err)
	} else {
		wantLangVersion := "go" + rootGoMinor
		if rootDprint.Gofumpt.LangVersion != wantLangVersion {
			errs = append(errs, fmt.Errorf("dprint.jsonc gofumpt.langVersion is %q, want %q (from go.mod)", rootDprint.Gofumpt.LangVersion, wantLangVersion))
		}
	}

	globalDprint, err := loadDprintConfig(filepath.Join(root, "config", "dprint", "dprint.jsonc"))
	if err != nil {
		errs = append(errs, err)
	}

	if rootDprint != nil && globalDprint != nil {
		errs = append(errs, compareCommonDprintPlugins(rootDprint.Plugins, globalDprint.Plugins)...)
	}

	return errors.Join(errs...)
}

func parseGoModVersion(path string) (full string, minor string, err error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", "", fmt.Errorf("reading %s: %w", path, err)
	}
	for _, line := range strings.Split(string(data), "\n") {
		fields := strings.Fields(strings.TrimSpace(line))
		if len(fields) >= 2 && fields[0] == "go" {
			full = fields[1]
			parts := strings.Split(full, ".")
			if len(parts) < 2 {
				return "", "", fmt.Errorf("%s: invalid go version %q", path, full)
			}
			return full, parts[0] + "." + parts[1], nil
		}
	}
	return "", "", fmt.Errorf("%s: go directive not found", path)
}

func loadDprintConfig(path string) (*dprintConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("reading %s: %w", path, err)
	}
	var cfg dprintConfig
	if err := json.Unmarshal(stripJSONCComments(data), &cfg); err != nil {
		return nil, fmt.Errorf("parsing %s: %w", path, err)
	}
	return &cfg, nil
}

func stripJSONCComments(src []byte) []byte {
	var out bytes.Buffer
	out.Grow(len(src))

	inString := false
	escaped := false
	for i := 0; i < len(src); i++ {
		c := src[i]
		if inString {
			out.WriteByte(c)
			if escaped {
				escaped = false
			} else if c == '\\' {
				escaped = true
			} else if c == '"' {
				inString = false
			}
			continue
		}

		if c == '"' {
			inString = true
			out.WriteByte(c)
			continue
		}
		if c == '/' && i+1 < len(src) {
			if src[i+1] == '/' {
				i += 2
				for i < len(src) && src[i] != '\n' {
					i++
				}
				if i < len(src) {
					out.WriteByte('\n')
				}
				continue
			}
			if src[i+1] == '*' {
				i += 2
				for i+1 < len(src) && !(src[i] == '*' && src[i+1] == '/') {
					i++
				}
				i++
				continue
			}
		}
		out.WriteByte(c)
	}
	return out.Bytes()
}

func parsePluginSpecs(plugins []string) map[string]string {
	m := make(map[string]string, len(plugins))
	for _, spec := range plugins {
		idx := strings.LastIndex(spec, "@")
		if idx <= 0 || idx == len(spec)-1 {
			continue
		}
		m[spec[:idx]] = spec[idx+1:]
	}
	return m
}

func compareCommonDprintPlugins(rootPlugins, globalPlugins []string) []error {
	rootMap := parsePluginSpecs(rootPlugins)
	globalMap := parsePluginSpecs(globalPlugins)

	var names []string
	for name := range rootMap {
		if _, ok := globalMap[name]; ok {
			names = append(names, name)
		}
	}
	slices.Sort(names)

	var errs []error
	for _, name := range names {
		if rootMap[name] != globalMap[name] {
			errs = append(errs, fmt.Errorf(
				"dprint plugin %s version mismatch: dprint.jsonc has %s, config/dprint/dprint.jsonc has %s",
				name, rootMap[name], globalMap[name],
			))
		}
	}
	return errs
}

func CheckByNamePrefixes(root string) error {
	byNameDir := filepath.Join(root, "pkgs", "by-name")
	prefixes, err := os.ReadDir(byNameDir)
	if err != nil {
		return fmt.Errorf("reading %s: %w", byNameDir, err)
	}

	var errs []error
	for _, prefixEntry := range prefixes {
		if !prefixEntry.IsDir() {
			continue
		}
		prefix := prefixEntry.Name()
		pkgEntries, err := os.ReadDir(filepath.Join(byNameDir, prefix))
		if err != nil {
			errs = append(errs, fmt.Errorf("reading %s/%s: %w", byNameDir, prefix, err))
			continue
		}
		for _, pkgEntry := range pkgEntries {
			if !pkgEntry.IsDir() {
				continue
			}
			pname := pkgEntry.Name()
			wantPrefix := expectedByNamePrefix(pname)
			if prefix != wantPrefix {
				errs = append(errs, fmt.Errorf("pkgs/by-name/%s/%s should be under prefix %q", prefix, pname, wantPrefix))
			}
			pkgNix := filepath.Join(byNameDir, prefix, pname, "package.nix")
			if _, err := os.Stat(pkgNix); err != nil {
				errs = append(errs, fmt.Errorf("pkgs/by-name/%s/%s is missing package.nix", prefix, pname))
			}
		}
	}
	return errors.Join(errs...)
}

func expectedByNamePrefix(pname string) string {
	lower := strings.ToLower(pname)
	if len(lower) <= 2 {
		return lower
	}
	return lower[:2]
}

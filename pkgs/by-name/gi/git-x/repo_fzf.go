package main

import (
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"sort"
	"strings"

	"github.com/kachick/dotfiles/pkgs/by-name/gi/git-x/internal/gitcmd"
)

type repoWorktreeEntry struct {
	relRepo   string
	label     string
	fullPath  string
	isDefault bool
}

func (e repoWorktreeEntry) formatLine() string {
	return fmt.Sprintf("%s\t%s\t%s", e.relRepo, e.label, e.fullPath)
}

func expandHomeTilde(path string) (string, error) {
	if path != "~" && !strings.HasPrefix(path, "~/") {
		return path, nil
	}
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("resolve home directory: %w", err)
	}
	if path == "~" {
		return homeDir, nil
	}
	return filepath.Join(homeDir, path[2:]), nil
}

func resolveRepoRoots() ([]string, error) {
	if envRoot := os.Getenv("GIT_X_ROOT"); envRoot != "" {
		var roots []string
		for raw := range strings.SplitSeq(envRoot, string(filepath.ListSeparator)) {
			if raw == "" {
				continue
			}
			expanded, err := expandHomeTilde(raw)
			if err != nil {
				return nil, err
			}
			roots = append(roots, filepath.Clean(expanded))
		}
		if len(roots) > 0 {
			return roots, nil
		}
	}

	cmd := gitcmd.NewIsolated(os.TempDir(), io.Discard, io.Discard).Command("config", "--path", "--get-all", "git-x.root")
	out, err := cmd.Output()
	if err != nil {
		var exitErr *exec.ExitError
		if !errors.As(err, &exitErr) || exitErr.ExitCode() != 1 {
			return nil, fmt.Errorf("git config --path --get-all git-x.root: %w", err)
		}
	} else {
		var roots []string
		for line := range strings.SplitSeq(string(out), "\n") {
			trimmed := strings.TrimSpace(line)
			if trimmed == "" {
				continue
			}
			expanded, err := expandHomeTilde(trimmed)
			if err != nil {
				return nil, err
			}
			roots = append(roots, filepath.Clean(expanded))
		}
		if len(roots) > 0 {
			return roots, nil
		}
	}

	homeDir, err := os.UserHomeDir()
	if err != nil {
		return nil, fmt.Errorf("resolve home directory: %w", err)
	}
	return []string{filepath.Join(homeDir, "repos")}, nil
}

func isDirEntryDir(parent string, entry os.DirEntry) bool {
	if entry.IsDir() {
		return true
	}
	if entry.Type()&os.ModeSymlink != 0 {
		return isDir(filepath.Join(parent, entry.Name()))
	}
	return false
}

func hasGitEntry(repoDir string) bool {
	_, err := os.Stat(filepath.Join(repoDir, ".git"))
	return err == nil
}

func listReposInRoots(roots []string) ([]string, error) {
	var repos []string

	for _, root := range roots {
		info, err := os.Stat(root)
		if err != nil {
			if os.IsNotExist(err) {
				continue
			}
			return nil, err
		}
		if !info.IsDir() {
			continue
		}

		hostEntries, err := os.ReadDir(root)
		if err != nil {
			return nil, err
		}
		for _, hostEntry := range hostEntries {
			if strings.HasPrefix(hostEntry.Name(), ".") || !isDirEntryDir(root, hostEntry) {
				continue
			}
			hostDir := filepath.Join(root, hostEntry.Name())
			ownerEntries, err := os.ReadDir(hostDir)
			if err != nil {
				return nil, err
			}
			for _, ownerEntry := range ownerEntries {
				if strings.HasPrefix(ownerEntry.Name(), ".") || !isDirEntryDir(hostDir, ownerEntry) {
					continue
				}
				ownerDir := filepath.Join(hostDir, ownerEntry.Name())
				repoEntries, err := os.ReadDir(ownerDir)
				if err != nil {
					return nil, err
				}
				for _, repoEntry := range repoEntries {
					if !isDirEntryDir(ownerDir, repoEntry) {
						continue
					}
					repoDir := filepath.Join(ownerDir, repoEntry.Name())
					if hasGitEntry(repoDir) {
						repos = append(repos, repoDir)
						// Do not descend into worktrees once the repository container is found.
						continue
					}
					if strings.HasPrefix(repoEntry.Name(), ".") {
						continue
					}
					subEntries, err := os.ReadDir(repoDir)
					if err != nil {
						continue
					}
					for _, subEntry := range subEntries {
						if strings.HasPrefix(subEntry.Name(), ".") || !isDirEntryDir(repoDir, subEntry) {
							continue
						}
						subRepoDir := filepath.Join(repoDir, subEntry.Name())
						if hasGitEntry(subRepoDir) {
							repos = append(repos, subRepoDir)
						}
					}
				}
			}
		}
	}

	slices.Sort(repos)
	return slices.Compact(repos), nil
}

func relativeToRoots(fullPath string, sortedRoots []string) string {
	cleanFull := filepath.Clean(fullPath)
	for _, root := range sortedRoots {
		prefix := root + string(filepath.Separator)
		if after, ok := strings.CutPrefix(cleanFull, prefix); ok {
			return filepath.ToSlash(after)
		}
	}
	return filepath.ToSlash(cleanFull)
}

func readHeadBranch(headPath string) string {
	data, err := os.ReadFile(headPath)
	if err != nil {
		return ""
	}
	content := strings.TrimSpace(string(data))
	if branch, ok := strings.CutPrefix(content, "ref: refs/heads/"); ok {
		return branch
	}
	return ""
}

func isBareConfig(configPath string) bool {
	data, err := os.ReadFile(configPath)
	if err != nil {
		return false
	}

	inCore := false
	for rawLine := range strings.SplitSeq(string(data), "\n") {
		line := strings.TrimSpace(rawLine)
		if line == "" || strings.HasPrefix(line, "#") || strings.HasPrefix(line, ";") {
			continue
		}
		if strings.HasPrefix(line, "[") && strings.HasSuffix(line, "]") {
			section := strings.ToLower(strings.TrimSpace(line[1 : len(line)-1]))
			inCore = section == "core"
			continue
		}
		if !inCore {
			continue
		}
		key, val, ok := strings.Cut(line, "=")
		if !ok {
			continue
		}
		if strings.EqualFold(strings.TrimSpace(key), "bare") {
			return strings.EqualFold(strings.TrimSpace(val), "true")
		}
	}
	return false
}

func readWorktreePath(gitdirFile string) (string, bool) {
	data, err := os.ReadFile(gitdirFile)
	if err != nil {
		return "", false
	}
	raw := strings.TrimSpace(string(data))
	if raw == "" {
		return "", false
	}
	wtPath := filepath.Clean(strings.TrimSuffix(raw, "/.git"))
	if !filepath.IsAbs(wtPath) {
		wtPath = filepath.Clean(filepath.Join(filepath.Dir(gitdirFile), wtPath))
	}
	info, err := os.Stat(wtPath)
	if err != nil || !info.IsDir() {
		return "", false
	}
	return wtPath, true
}

func repoWorktreeLabel(repoDir, wtPath string) string {
	rel, err := filepath.Rel(repoDir, wtPath)
	if err == nil && rel != "." && !strings.HasPrefix(rel, "..") {
		// Replace "/" so fzf's --delimiter='[/\t]' keeps field indices aligned.
		return strings.ReplaceAll(filepath.ToSlash(rel), "/", "-")
	}
	return filepath.Base(wtPath)
}

func inspectRepoWorktrees(relRepo, repoDir string) []repoWorktreeEntry {
	gitDir := filepath.Join(repoDir, ".git")
	info, err := os.Stat(gitDir)
	if err != nil || !info.IsDir() {
		return []repoWorktreeEntry{{relRepo: relRepo, label: ".", fullPath: repoDir, isDefault: true}}
	}

	defaultBranch := readHeadBranch(filepath.Join(gitDir, "HEAD"))
	bare := isBareConfig(filepath.Join(gitDir, "config"))

	var linked []repoWorktreeEntry
	wtRoot := filepath.Join(gitDir, "worktrees")
	if wtDirs, err := os.ReadDir(wtRoot); err == nil {
		for _, entry := range wtDirs {
			if !entry.IsDir() {
				continue
			}
			wtMetaDir := filepath.Join(wtRoot, entry.Name())
			wtPath, ok := readWorktreePath(filepath.Join(wtMetaDir, "gitdir"))
			if !ok {
				continue
			}
			label := repoWorktreeLabel(repoDir, wtPath)
			wtBranch := readHeadBranch(filepath.Join(wtMetaDir, "HEAD"))
			isDef := defaultBranch != "" && (wtBranch == defaultBranch || label == defaultBranch)
			linked = append(linked, repoWorktreeEntry{
				relRepo:   relRepo,
				label:     label,
				fullPath:  wtPath,
				isDefault: isDef,
			})
		}
	}

	sort.SliceStable(linked, func(i, j int) bool {
		if linked[i].isDefault != linked[j].isDefault {
			return linked[i].isDefault
		}
		return linked[i].label < linked[j].label
	})

	if !bare {
		// Legacy non-bare repository: emit main working tree first, followed by any linked worktrees.
		entries := make([]repoWorktreeEntry, 0, 1+len(linked))
		entries = append(entries, repoWorktreeEntry{
			relRepo:   relRepo,
			label:     ".",
			fullPath:  repoDir,
			isDefault: true,
		})
		entries = append(entries, linked...)
		return entries
	}

	if len(linked) == 0 {
		return []repoWorktreeEntry{{relRepo: relRepo, label: "(bare)", fullPath: repoDir, isDefault: true}}
	}
	return linked
}

func collectAllWorktrees() ([]repoWorktreeEntry, error) {
	roots, err := resolveRepoRoots()
	if err != nil {
		return nil, err
	}
	sortedRoots := slices.Clone(roots)
	sort.Slice(sortedRoots, func(i, j int) bool {
		return len(sortedRoots[i]) > len(sortedRoots[j])
	})

	fullPaths, err := listReposInRoots(roots)
	if err != nil {
		return nil, err
	}

	var result []repoWorktreeEntry
	for _, fullPath := range fullPaths {
		rel := relativeToRoots(fullPath, sortedRoots)
		result = append(result, inspectRepoWorktrees(rel, fullPath)...)
	}
	return result, nil
}

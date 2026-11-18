package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
)

type ghqWorktreeEntry struct {
	relRepo   string
	label     string
	fullPath  string
	isDefault bool
}

func (e ghqWorktreeEntry) formatLine() string {
	return fmt.Sprintf("%s\t%s\t%s", e.relRepo, e.label, e.fullPath)
}

func runCommandLines(name string, args ...string) ([]string, error) {
	cmd := exec.Command(name, args...)
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("%s %s: %w", name, strings.Join(args, " "), err)
	}
	var lines []string
	for line := range strings.SplitSeq(strings.TrimSpace(string(out)), "\n") {
		line = strings.TrimSpace(line)
		if line != "" {
			lines = append(lines, line)
		}
	}
	return lines, nil
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

func ghqWorktreeLabel(repoDir, wtPath string) string {
	rel, err := filepath.Rel(repoDir, wtPath)
	if err == nil && rel != "." && !strings.HasPrefix(rel, "..") {
		// Replace "/" so fzf's --delimiter='[/\t]' keeps field indices aligned.
		return strings.ReplaceAll(filepath.ToSlash(rel), "/", "-")
	}
	return filepath.Base(wtPath)
}

func inspectRepoWorktrees(relRepo, repoDir string) []ghqWorktreeEntry {
	gitDir := filepath.Join(repoDir, ".git")
	info, err := os.Stat(gitDir)
	if err != nil || !info.IsDir() {
		return []ghqWorktreeEntry{{relRepo: relRepo, label: ".", fullPath: repoDir, isDefault: true}}
	}

	defaultBranch := readHeadBranch(filepath.Join(gitDir, "HEAD"))
	bare := isBareConfig(filepath.Join(gitDir, "config"))

	var linked []ghqWorktreeEntry
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
			label := ghqWorktreeLabel(repoDir, wtPath)
			wtBranch := readHeadBranch(filepath.Join(wtMetaDir, "HEAD"))
			isDef := defaultBranch != "" && (wtBranch == defaultBranch || label == defaultBranch)
			linked = append(linked, ghqWorktreeEntry{
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
		entries := make([]ghqWorktreeEntry, 0, 1+len(linked))
		entries = append(entries, ghqWorktreeEntry{
			relRepo:   relRepo,
			label:     ".",
			fullPath:  repoDir,
			isDefault: true,
		})
		entries = append(entries, linked...)
		return entries
	}

	if len(linked) == 0 {
		return []ghqWorktreeEntry{{relRepo: relRepo, label: "(bare)", fullPath: repoDir, isDefault: true}}
	}
	return linked
}

func collectAllWorktrees() ([]ghqWorktreeEntry, error) {
	roots, err := runCommandLines("ghq", "root", "--all")
	if err != nil {
		return nil, err
	}
	for i, r := range roots {
		roots[i] = filepath.Clean(r)
	}
	sort.Slice(roots, func(i, j int) bool {
		return len(roots[i]) > len(roots[j])
	})

	fullPaths, err := runCommandLines("ghq", "list", "--full-path")
	if err != nil {
		return nil, err
	}

	var result []ghqWorktreeEntry
	for _, fullPath := range fullPaths {
		rel := relativeToRoots(fullPath, roots)
		result = append(result, inspectRepoWorktrees(rel, fullPath)...)
	}
	return result, nil
}

func ghqFzfFilterArgs(query string) []string {
	return []string{
		"--query", query,
		// Expects 3-level `<host>/<owner>/<repo>` paths; deeper paths (e.g. GitLab subgroups) are rare here.
		// Splitting `<repo>` with `\t` would add tab gaps in the path and make the boundary with worktree labels unclear.
		"--delimiter=[/\t]",
		"--nth=3,4",
		"--with-nth=1..4",
		"--accept-nth=5..",
		"--tiebreak=begin,index",
		"--preview", "eza --group-directories-first --icons=always --color=always --no-user --no-time --no-filesize --no-permissions --sort=modified {5..}",
		"--preview-window", "~3",
	}
}

func runGhqFzf(args []string, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("gitx ghq-fzf", flag.ContinueOnError)
	fs.SetOutput(stderr)
	listOnly := fs.Bool("list", false, "print flat worktree entries without invoking fzf")

	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: gitx ghq-fzf [--list] [query]\n\n")
		fmt.Fprintf(stderr, "Select a repository worktree via fzf and print its path.\n\n")
		fs.PrintDefaults()
	}

	if err := fs.Parse(args); err != nil {
		return err
	}

	var query string
	remaining := fs.Args()
	if len(remaining) >= 1 {
		query = remaining[0]
	}

	entries, err := collectAllWorktrees()
	if err != nil {
		return err
	}

	var input strings.Builder
	for _, entry := range entries {
		input.WriteString(entry.formatLine())
		input.WriteByte('\n')
	}

	if *listOnly {
		_, err := io.WriteString(stdout, input.String())
		return err
	}

	if len(entries) == 0 {
		return nil
	}

	cmd := exec.Command("fzf", ghqFzfFilterArgs(query)...)
	cmd.Stdin = strings.NewReader(input.String())
	cmd.Stdout = stdout
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		if isCancelExitError(err) {
			return nil
		}
		return fmt.Errorf("fzf failed: %w", err)
	}
	return nil
}

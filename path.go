package dotfiles

import (
	"io/fs"
	"path/filepath"
	"strings"

	"golang.org/x/exp/slices"
)

func GetTyposTargetedRoots() []string {
	return []string{
		".",
		".github", ".vscode",
		"home/.config", "home/.stack",
	}
}

type WalkedReport struct {
	Path string
	Dir  fs.DirEntry
}

type Walker struct {
	ignoredDirectories []string
	reports            []WalkedReport
}

func GetWalker() Walker {
	w := Walker{
		ignoredDirectories: []string{".git", ".direnv", "dist", "dependencies"},
	}
	w.reports = w.GetReports()

	return w
}

func (w Walker) GetReports() []WalkedReport {
	paths := []WalkedReport{}
	filepath.WalkDir(".", func(path string, d fs.DirEntry, err error) error {
		if d.IsDir() {
			if slices.Contains(w.ignoredDirectories, d.Name()) {
				return fs.SkipDir
			}
		}
		paths = append(paths, WalkedReport{
			Path: path,
			Dir:  d,
		})
		return nil
	})
	return paths
}

func (w Walker) GetAllBash() []string {
	paths := []string{}

	for _, r := range w.reports {
		if strings.HasSuffix(r.Dir.Name(), ".bash") ||
			(strings.HasPrefix(r.Dir.Name(), "bash") && !strings.HasSuffix(r.Dir.Name(), ".nix")) {
			paths = append(paths, r.Path)
		}
	}

	return paths
}

func (w Walker) GetAllNix() []string {
	paths := []string{}

	for _, r := range w.reports {
		if strings.HasSuffix(r.Dir.Name(), ".nix") {
			paths = append(paths, r.Path)
		}
	}

	return paths
}

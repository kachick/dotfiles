package fileutils

import (
	"io/fs"
	"path/filepath"
	"strings"

	"golang.org/x/exp/slices"
)

type WalkedReport struct {
	Path string
	Dir  fs.DirEntry
}

type Walker struct {
	ignoredDirectories []string
	reports            []WalkedReport
}

func GetWalker() Walker {
	//exhaustruct:ignore
	w := Walker{
		ignoredDirectories: []string{".git", ".direnv", "dist", "result", "tmp", "dependencies"},
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

func (w Walker) GetAllMarkdown() []string {
	paths := []string{}

	for _, r := range w.reports {
		if !r.Dir.IsDir() && strings.HasSuffix(r.Dir.Name(), ".md") {
			paths = append(paths, r.Path)
		}
	}

	return paths
}

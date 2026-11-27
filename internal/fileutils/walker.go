package fileutils

import (
	"io/fs"
	"path/filepath"
	"slices"
	"strings"
)

type WalkedReport struct {
	Path string
	Dir  fs.DirEntry
}

type Walker struct {
	ignoredDirectories []string
	reports            []WalkedReport
}

func GetWalker() (Walker, error) {
	return GetWalkerIn(".")
}

func GetWalkerIn(root string) (Walker, error) {
	w := Walker{
		ignoredDirectories: []string{".git", ".direnv", "dist", "result", "tmp"},
	}
	reports, err := w.walk(root)
	if err != nil {
		return Walker{}, err
	}
	w.reports = reports

	return w, nil
}

func (w Walker) walk(root string) ([]WalkedReport, error) {
	paths := []WalkedReport{}
	err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
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
	if err != nil {
		return nil, err
	}
	return paths, nil
}

func (w Walker) GetAllBash() []string {
	paths := []string{}

	for _, r := range w.reports {
		if r.Dir.IsDir() {
			continue
		}
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
		if r.Dir.IsDir() {
			continue
		}
		if strings.HasSuffix(r.Dir.Name(), ".nix") {
			paths = append(paths, r.Path)
		}
	}

	return paths
}

func (w Walker) GetAllDesktop() []string {
	paths := []string{}

	for _, r := range w.reports {
		if r.Dir.IsDir() {
			continue
		}
		if strings.HasSuffix(r.Dir.Name(), ".desktop") {
			paths = append(paths, r.Path)
		}
	}

	return paths
}

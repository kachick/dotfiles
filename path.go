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
		"home/.config", "home/.local", "home/.stack",
	}
}

func checkIgnoreDir(d fs.DirEntry) error {
	if d.IsDir() {
		if slices.Contains([]string{".git", ".direnv", "dist"}, d.Name()) {
			return fs.SkipDir
		}
	}
	return nil
}

func GetAllBash() []string {
	bashPaths := []string{}
	filepath.WalkDir(".", func(path string, d fs.DirEntry, err error) error {
		if err := checkIgnoreDir(d); err != nil {
			return err
		}
		if strings.HasSuffix(d.Name(), ".bash") {
			bashPaths = append(bashPaths, path)
		}
		return nil
	})

	return bashPaths
}

func GetAllNix() []string {
	nixPaths := []string{}

	filepath.WalkDir(".", func(path string, d fs.DirEntry, err error) error {
		if err := checkIgnoreDir(d); err != nil {
			return err
		}
		if strings.HasSuffix(d.Name(), ".nix") {
			nixPaths = append(nixPaths, path)
		}
		return nil
	})

	return nixPaths
}

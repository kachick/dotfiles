package dotfiles

import (
	"io/fs"
	"log"

	"github.com/bmatcuk/doublestar/v4"
)

func GetTyposTargetedRoots() []string {
	return []string{
		".",
		".github", ".vscode",
		"home/.config", "home/.local", "home/.stack",
	}
}

func MustGetAllBash(fsys fs.FS) []string {
	bashPaths, err := doublestar.Glob(fsys, "./**/{*.bash,.bash*}")
	if err != nil {
		log.Fatalln(err)
	}
	return bashPaths
}

func MustGetAllNix(fsys fs.FS) []string {
	nixPaths, err := doublestar.Glob(fsys, "./**/*.nix")
	if err != nil {
		log.Fatalln(err)
	}
	return nixPaths
}

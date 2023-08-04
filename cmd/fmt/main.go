package main

import (
	"log"
	"os"

	doublestar "github.com/bmatcuk/doublestar/v4"

	"github.com/kachick/dotfiles"
)

func main() {
	wd, err := os.Getwd()
	if err != nil {
		log.Fatalln(err)
	}
	fsys := os.DirFS(wd)

	bashPaths, err := doublestar.Glob(fsys, "./**/{*.bash,.bash*}")
	if err != nil {
		log.Fatalln(err)
	}
	nixPaths, err := doublestar.Glob(fsys, "./**/*.nix")
	if err != nil {
		log.Fatalln(err)
	}

	// Do not cover the same files in another formatter for parallel processing
	cmds := dotfiles.Commands{
		{Path: "dprint", Args: []string{"fmt"}},
		{Path: "shfmt", Args: append([]string{"--language-dialect", "bash", "--write"}, bashPaths...)},
		{Path: "nixpkgs-fmt", Args: nixPaths},
		{Path: "typos", Args: append(dotfiles.GetTyposTargetedRoots(), "--write-changes")},
		{Path: "go", Args: []string{"fmt", "./..."}},
	}

	cmds.ParallelRun()
}

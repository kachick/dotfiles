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

	cmds := dotfiles.Commands{
		{Path: "dprint", Args: []string{"check"}},
		{Path: "shfmt", Args: append([]string{"--language-dialect", "bash", "--diff"}, bashPaths...)},
		{Path: "shellcheck", Args: bashPaths},
		{Path: "nixpkgs-fmt", Args: append([]string{"--check"}, nixPaths...)},
		{Path: "typos", Args: dotfiles.GetTyposTargetedRoots()},
		{Path: "gitleaks", Args: []string{"detect"}},
		{Path: "go", Args: []string{"vet", "./..."}},
	}

	cmds.ParallelRun()
}

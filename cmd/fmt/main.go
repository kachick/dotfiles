package main

import (
	"log"
	"os"

	"github.com/kachick/dotfiles"
)

func main() {
	wd, err := os.Getwd()
	if err != nil {
		log.Fatalln(err)
	}
	fsys := os.DirFS(wd)

	bashPaths := dotfiles.MustGetAllBash(fsys)
	nixPaths := dotfiles.MustGetAllNix(fsys)

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

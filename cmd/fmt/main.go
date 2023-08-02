package main

import (
	"log"
	"os"
	"os/exec"
	"strings"
	"sync"

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

	type command struct {
		path string
		args []string
	}

	// Do not cover the same files in another formatter for parallel processing
	cmds := []command{
		{"dprint", []string{"fmt"}},
		{"shfmt", append([]string{"--language-dialect", "bash", "--write"}, bashPaths...)},
		{"nixpkgs-fmt", nixPaths},
		{"typos", append(dotfiles.GetTyposTargetedRoots(), "--write-changes")},
		{"go", []string{"fmt", "./..."}},
	}

	wg := &sync.WaitGroup{}
	for _, cmd := range cmds {
		wg.Add(1)
		go func(cmd command) {
			defer wg.Done()
			output, err := exec.Command(cmd.path, cmd.args...).Output()
			log.Printf("%s %s\n%s\n", cmd.path, strings.Join(cmd.args, " "), output)
			if err != nil {
				log.Fatalln(err)
			}
		}(cmd)
	}
	wg.Wait()
}

package main

import (
	"log"
	"os"
	"os/exec"
	"strings"

	doublestar "github.com/bmatcuk/doublestar/v4"
)

func main() {
	wd, err := os.Getwd()
	if err != nil {
		log.Fatalln(err)
	}
	fsys := os.DirFS(wd)

	bashPaths, err := doublestar.Glob(fsys, "./**/*.bash")
	if err != nil {
		log.Fatalln(err)
	}
	nixPaths, err := doublestar.Glob(fsys, "./**/*.nix")
	if err != nil {
		log.Fatalln(err)
	}

	cmds := []struct {
		path string
		args []string
	}{
		{"dprint", []string{"check"}},
		{"shfmt", append([]string{"--language-dialect", "bash", "--diff"}, bashPaths...)},
		{"shellcheck", bashPaths},
		{"nixpkgs-fmt", append([]string{"--check"}, nixPaths...)},
		{"typos", []string{".", ".github", "home/.config", ".vscode"}},
		{"gitleaks", []string{"detect"}},
		{"go", []string{"vet", "./..."}},
	}

	for _, cmd := range cmds {
		output, err := exec.Command(cmd.path, cmd.args...).Output()
		log.Printf("%s %s\n%s\n", cmd.path, strings.Join(cmd.args, " "), output)
		if err != nil {
			log.Fatalln(err)
		}
	}
}

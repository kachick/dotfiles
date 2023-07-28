package main

import (
	"log"
	"os/exec"
	"strings"
)

func main() {
	cmds := []struct {
		path string
		args []string
	}{
		{"go", []string{"version"}},
		{"makers", []string{"--version"}},
		{"nix", []string{"--version"}},
		{"dprint", []string{"--version"}},
		{"shellcheck", []string{"--version"}},
		{"shfmt", []string{"--version"}},
		{"typos", []string{"--version"}},
		{"gitleaks", []string{"version"}},
	}

	for _, cmd := range cmds {
		output, err := exec.Command(cmd.path, cmd.args...).Output()
		log.Printf("%s %s\n%s\n", cmd.path, strings.Join(cmd.args, " "), output)
		if err != nil {
			log.Fatalln(err)
		}
	}
}

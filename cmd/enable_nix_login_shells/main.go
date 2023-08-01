package main

import (
	"fmt"
	"log"
	"os"
	"strings"
)

// Called should be `sudo -E ...`, See https://stackoverflow.com/a/40438345/1212807

// This script requires sudo execution, if it is a reasonable way, including in home.nix may be better

func main() {
	homePath, ok := os.LookupEnv("HOME")
	if !ok {
		log.Fatalln("$HOME is not found")
	}
	if homePath == "/root" {
		log.Fatalln("used by root looks weird. You should run `sudo -E ...` instead of `sudo ...`")
	}

	loginableShells := []string{"bash", "zsh", "fish"}

	etcShellsBytes, err := os.ReadFile("/etc/shells")
	if err != nil {
		log.Fatalf("%v\n", err)
	}

	etcShells := string(etcShellsBytes)
	dirty := strings.Clone(etcShells)
	examplePath := ""

	for _, sh := range loginableShells {
		shellPath := homePath + "/.nix-profile/bin/" + sh
		if strings.Contains(etcShells, shellPath) {
			log.Printf("skip - %s is already registered in /etc/shells\n", shellPath)
		} else {
			log.Printf("insert - %s will be registered in /etc/shells\n", shellPath)
			examplePath = shellPath
			dirty += fmt.Sprintln(shellPath)
		}
	}

	if dirty != etcShells {
		err = os.WriteFile("/etc/shells", []byte(dirty), os.ModePerm)
		if err != nil {
			log.Fatalf("failed - could you correctly run this with sudo? - %v\n", err)
		}

		fmt.Printf(`
Done! Set one of your favorite shell as follows

chsh -s %s "$(whoami)"
`, examplePath)
	}
}

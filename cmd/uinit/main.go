//go:build linux || darwin

package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/user"
	"strings"
)

func usage() string {
	return `Usage: uinit [OPTIONS]

Linux and macOS initialization

- Require root privileges as sudo
- Specify one of non root user for the target

$ sudo uinit --user=runner # dry_run by default
$ sudo uinit --user="$(whoami)" --dry_run=false
`
}

func getShellPath(homePath string, shellName string) string {
	return homePath + "/.nix-profile/bin/" + shellName
}

func main() {
	userFlag := flag.String("user", "", "affect for the given user")
	dryRunFlag := flag.Bool("dry_run", true, "no side effect if true")
	flag.Usage = func() {
		// https://github.com/golang/go/issues/57059#issuecomment-1336036866
		fmt.Printf("%s", usage()+"\n\n")
		fmt.Println("Usage of command:")
		flag.PrintDefaults()
		fmt.Println("")
	}
	flag.Parse()

	username := *userFlag
	if username == "" || username == "root" {
		flag.Usage()
		os.Exit(1)
	}

	target, err := user.Lookup(username)
	if err != nil {
		log.Fatalf("Given user %s is not found: %v", username, err)
	}

	if *dryRunFlag {
		log.Println("Running in DRY RUN mode. You can toggle by --dry_run flag")
	}

	const primaryShell = "zsh"
	loginableShells := []string{primaryShell, "bash", "fish"}

	etcShellsBytes, err := os.ReadFile("/etc/shells")
	if err != nil {
		log.Fatalf("%v\n", err)
	}

	etcShells := string(etcShellsBytes)
	dirty := strings.Clone(etcShells)

	for _, sh := range loginableShells {
		shellPath := getShellPath(target.HomeDir, sh)
		if strings.Contains(etcShells, shellPath) {
			log.Printf("skip - %s is already registered in /etc/shells\n", shellPath)
		} else {
			log.Printf("insert - %s will be registered in /etc/shells\n", shellPath)
			dirty += fmt.Sprintln(shellPath)
		}
	}

	if dirty == etcShells {
		log.Printf("No changes have been made")
	} else {
		if !*dryRunFlag {
			err = os.WriteFile("/etc/shells", []byte(dirty), os.ModePerm)
			if err != nil {
				log.Fatalf("You should run this command with root privileges as sudo - %v\n", err)
			}
		}

		log.Printf(`Done! Set one of your favorite shell as follows

chsh -s %s "$(whoami)"
`, getShellPath(target.HomeDir, primaryShell))
	}
}

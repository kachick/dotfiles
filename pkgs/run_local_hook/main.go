package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

func usage() {
	fmt.Println(
		"Usage: run_local_hook <hook_name> [args...]",
		"You should remove local hooks as `git config --local --unset core.hooksPath` to prefer global hooks for the entry point",
	)
}

func main() {
	log.SetFlags(log.Flags() &^ (log.Ldate | log.Ltime))

	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}

	hookName := os.Args[1]
	args := os.Args[2:]

	repoPathCmd := exec.Command("git", "rev-parse", "--show-toplevel")
	repoPathBytes, err := repoPathCmd.Output()
	if err != nil {
		fmt.Println("Error getting repository path:", err)
		os.Exit(1)
	}

	repoPath := strings.TrimSpace(string(repoPathBytes))
	trustedPaths := os.Getenv("GIT_HOOKS_TRUST_REPOS")

	localHookPath := fmt.Sprintf("%s/.git/hooks/%s", repoPath, hookName)
	if _, err := os.Stat(localHookPath); os.IsNotExist(err) {
		return
	}

	if !strings.Contains(":"+trustedPaths+":", ":"+repoPath+":") {
		fmt.Println("Found an ignored local hook.")
		fmt.Println("You can allow it as:")
		fmt.Printf("export GIT_HOOKS_TRUST_REPOS=\"%s:$PWD\"\n", trustedPaths)
		return
	}

	cmd := exec.Command(localHookPath, args...)
	cmd.Stdin = os.Stdin // pre-push depends on STDIN
	out, err := cmd.CombinedOutput()
	log.Println(string(out))
	if err != nil {
		log.Fatal("failed to run local hook %w", err)
	}
}

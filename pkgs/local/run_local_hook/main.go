package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"slices"
	"strings"
)

func usage() {
	fmt.Println(
		"Usage: run_local_hook <hook_name> [args...]",
		"You should remove local hooks as `git config --local --unset core.hooksPath` to prefer global hooks for the entry point",
	)
}

func getRepoPath() (string, error) {
	cmd := exec.Command("git", "rev-parse", "--show-toplevel")
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

func main() {
	log.SetFlags(log.Flags() &^ (log.Ldate | log.Ltime))

	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}

	hookName := os.Args[1]
	args := os.Args[2:]

	repoPath, err := getRepoPath()
	if err != nil {
		log.Fatalf("failed to get repository path: %+v", err)
		os.Exit(1)
	}
	trustedPaths := strings.Split(os.Getenv("GIT_HOOKS_TRUST_REPOS"), ":")

	hooksDir := filepath.Join(repoPath, ".git", "hooks")
	localHookPath := filepath.Join(hooksDir, hookName)

	// Ensure the resulting path is still within the .git/hooks directory to prevent path traversal
	rel, err := filepath.Rel(hooksDir, localHookPath)
	if err != nil || strings.HasPrefix(rel, "..") || filepath.IsAbs(rel) {
		log.Fatalf("invalid hook name: %s\n", hookName)
	}

	if _, err := os.Stat(localHookPath); os.IsNotExist(err) {
		return
	}

	if !slices.Contains(trustedPaths, repoPath) {
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

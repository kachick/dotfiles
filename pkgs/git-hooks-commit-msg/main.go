package main

import (
	"log"
	"os"
	"os/exec"
	"strings"

	"github.com/kachick/dotfiles/internal/githooks"
)

var (
	TyposConfigPath string
)

// Spec of Git: https://git-scm.com/docs/githooks#_commit_msg
// Summarizing for me, content of commit message will be written in a tempfile which is typically be .git/COMMIT_EDITMSG. The filepath will be given with $1.
func main() {
	log.SetFlags(log.Flags() &^ (log.Ldate | log.Ltime))

	if len(os.Args) < 2 {
		log.Fatalln("Body of commit message is not given with $1")
	}
	msgPath := os.Args[1]

	shouldSkip := githooks.MakeSkipChecker()

	linters := initializeLinters(msgPath)
	if err := githooks.RunLinters(linters, shouldSkip); err != nil {
		log.Fatalf("Failed to run global hook: %+v", err)
	}

	if shouldSkip("localhook") {
		return
	}

	if err := runLocalHook(msgPath); err != nil {
		log.Fatalf("Failed to run local hook: %+v", err)
	}
}

func initializeLinters(msgPath string) map[string]githooks.Linter {
	return map[string]githooks.Linter{
		"prevent secrets in the message": githooks.Linter{Tag: "gitleaks", Script: func() error {
			cmd := exec.Command("gitleaks", "--verbose", "stdin", msgPath)
			f, err := os.Open(msgPath)
			if err != nil {
				return err
			}
			defer f.Close()

			cmd.Stdin = f
			log.Println(strings.Join(cmd.Args, " "))
			out, err := cmd.CombinedOutput()
			log.Println(string(out))
			return err
		}},
		"prevent typos in the message": githooks.Linter{Tag: "typos", Script: func() error {
			cmd := exec.Command("typos", "--config", TyposConfigPath, msgPath)
			out, err := cmd.CombinedOutput()
			log.Println(strings.Join(cmd.Args, " "))
			log.Println(string(out))
			return err
		}},
	}
}

// Don't run global and local hooks together in parallel tasks, because of we don't assume local hooks do not have any side-effect
func runLocalHook(msgPath string) error {
	log.Println("run local hook")
	out, err := exec.Command("run_local_hook", "commit-msg", msgPath).CombinedOutput()
	log.Println(string(out))
	return err
}

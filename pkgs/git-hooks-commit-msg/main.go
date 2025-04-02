package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"slices"
	"strings"
	"sync"
)

var (
	TyposConfigPath string
)

type Linter struct {
	Tag    string
	Script func() error
}

// Spec of Git: https://git-scm.com/docs/githooks#_commit_msg
// Summarizing for me, content of commit message will be written in a tempfile which is typically be .git/COMMIT_EDITMSG. The filepath will be given with $1.
func main() {
	log.SetFlags(log.Flags() &^ (log.Ldate | log.Ltime))

	if len(os.Args) < 2 {
		log.Fatalln("Body of commit message is not given with $1")
	}
	msgPath := os.Args[1]

	shouldSkip := makeSkipChecker()

	linters := initializeLinters(msgPath)
	runLinters(linters, shouldSkip)

	if shouldSkip("localhook") {
		return
	}

	if err := runLocalHook(msgPath); err != nil {
		log.Fatalf("Failed to run local hook: %w", err)
	}
}

func makeSkipChecker() func(string) bool {
	// `SKIP` is adjusted for pre-commit convention. See https://github.com/gitleaks/gitleaks/blob/v8.24.0/README.md?plain=1#L121-L127
	// Unnecessary to consider strict CSV spec such as https://pre-commit.com/
	skips := strings.Split(os.Getenv("SKIP"), ",")

	return func(tag string) bool {
		return slices.Contains(skips, tag)
	}
}

func runLinters(linters map[string]Linter, shouldSkip func(string) bool) error {
	var mu sync.Mutex
	errs := map[string]error{}
	wg := &sync.WaitGroup{}

	for desc, linter := range linters {
		if shouldSkip(linter.Tag) {
			continue
		}

		wg.Add(1)
		go func(desc string, linter Linter) {
			defer wg.Done()
			log.Println(desc)
			if err := linter.Script(); err != nil {
				mu.Lock()
				errs[desc] = err
				mu.Unlock()
			}
		}(desc, linter)
	}
	wg.Wait()

	if len(errs) > 0 {
		return fmt.Errorf("linter errors: %v", errs)
	}
	return nil
}

func initializeLinters(msgPath string) map[string]Linter {
	return map[string]Linter{
		"prevent secrets in the message": Linter{Tag: "gitleaks", Script: func() error {
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
		"prevent typos in the message": Linter{Tag: "typos", Script: func() error {
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

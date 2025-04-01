package main

import (
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

// Spec of Git: Content of commit message will be written in a tempfile. The filepath will be given with $1
func main() {
	log.SetFlags(log.Flags() &^ (log.Ldate | log.Ltime))

	if !(len(os.Args) > 1) {
		log.Fatalln("Body of commit message is not given with $1")
	}
	msgPath := os.Args[1]

	// `SKIP` is adjusted for pre-commit convention. See https://github.com/gitleaks/gitleaks/blob/v8.24.0/README.md?plain=1#L121-L127
	// Unnecessary to consider strict CSV spec such as https://pre-commit.com/
	skips := strings.Split(os.Getenv("SKIP"), ",")

	linters := map[string]Linter{
		"prevent secrets in the message": Linter{Tag: "gitleaks", Script: func() error {
			cmd := exec.Command("gitleaks", "--verbose", "stdin", msgPath)
			f, err := os.Open(msgPath)
			if err != nil {
				log.Fatalf("%w", err)
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

	wg := &sync.WaitGroup{}
	for desc, linter := range linters {
		// Unnecessary to consider large slice is given. So nested iterations do not make problem here
		if !slices.Contains(skips, linter.Tag) {
			wg.Add(1)
			go func(linter Linter) {
				defer wg.Done()
				log.Println(desc)
				err := linter.Script()
				if err != nil {
					log.Fatalln(err)
				}
			}(linter)
		}
	}
	wg.Wait()

	// Don't include in above parallel tasks, because of we don't assume local hooks do not have any side-effect
	exec.Command("run_local_hook", append([]string{"commit-msg"}, os.Args[1:]...)...).CombinedOutput()
}

type Linter struct {
	Tag    string
	Script func() error
}

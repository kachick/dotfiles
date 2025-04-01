package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"
	"slices"
	"strings"
	"sync"

	pipeline "github.com/mattn/go-pipeline"
)

var (
	TyposConfigPath string
)

// Spec of Git: https://git-scm.com/docs/githooks#_pre_push
func main() {
	log.SetFlags(log.Flags() &^ (log.Ldate | log.Ltime))

	remoteDefaultBranch, err := getRemoteDefaultBranch()
	if err != nil {
		log.Fatalln("Can't get default branch of the remote repository")
	}

	// `SKIP` is adjusted for pre-commit convention. See https://github.com/gitleaks/gitleaks/blob/v8.24.0/README.md?plain=1#L121-L127
	// Unnecessary to consider strict CSV spec such as https://pre-commit.com/
	skips := strings.Split(os.Getenv("SKIP"), ",")

	wg := &sync.WaitGroup{}
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		line := scanner.Text()
		linters, err := processLine(line, remoteDefaultBranch)
		if err != nil {
			fmt.Println("Error:", err)
		}
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
	}
	wg.Wait()

	if err := scanner.Err(); err != nil {
		fmt.Println("Error reading input:", err)
		os.Exit(1)
	}

	// Don't include in above parallel tasks, because of we don't assume local hooks do not have any side-effect
	// FIXME: It should process for same STDIN in both local and global hook. So delegating "$@" is not enough
	exec.Command("run_local_hook", append([]string{"pre-push"}, os.Args[1:]...)...).CombinedOutput()
}

type Linter struct {
	Tag    string
	Script func() error
}

func processLine(line string, remoteBranch string) (map[string]Linter, error) {
	fields := strings.Fields(line)
	if len(fields) != 4 {
		return nil, fmt.Errorf("parsing error for given line: %s", line)
	}

	localRef := fields[0]
	// localOid := fields[1]
	remoteRef := fields[2]
	// remoteOid := fields[3]

	return map[string]Linter{
		"prevent secrets in log and diff": Linter{Tag: "gitleaks", Script: func() error {
			cmd := exec.Command("gitleaks", "--verbose", "git", fmt.Sprintf("--log-opts=%s..%s", remoteBranch, localRef))
			out, err := cmd.CombinedOutput()
			log.Println(strings.Join(cmd.Args, " "))
			log.Println(string(out))
			return err
		}},
		"prevent typos in log and diff": Linter{Tag: "typos", Script: func() error {
			out, err := pipeline.CombinedOutput(
				[]string{"git", "log", "--patch", fmt.Sprintf("%s..%s", remoteBranch, localRef)},
				[]string{"typos", "--config", TyposConfigPath, "-"},
			)
			log.Println(string(out))
			return err
		}},
		"prevent typos in branch name": Linter{Tag: "typos", Script: func() error {
			out, err := pipeline.CombinedOutput(
				[]string{"basename", remoteRef}, // Rewrite with go
				[]string{"typos", "--config", TyposConfigPath, "-"},
			)
			log.Println(string(out))
			return err
		}},
	}, nil
}

func getRemoteDefaultBranch() (string, error) {
	cmd := exec.Command("git", "symbolic-ref", "refs/remotes/origin/HEAD")
	out, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get remote default branch: %w", err)
	}
	return strings.TrimSpace(string(out)), nil
}

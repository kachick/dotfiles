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

	cmds := Scenarios{}

	// Unnecessary to consider strict CSV spec such as https://pre-commit.com/
	skips := strings.Split(os.Getenv("SKIP"), ",")
	// Unnecessary to consider large slugs. So multiple iterations does not make problem
	if !slices.Contains(skips, "typos") {
		cmds = append(cmds, func() Scenario {
			return Scenario{cmd: exec.Command("typos", "--config", TyposConfigPath, msgPath), cleanup: func() {}}
		}())
	}
	if !slices.Contains(skips, "gitleaks") {
		cmds = append(cmds, func() Scenario {
			cmd := exec.Command("gitleaks", "--verbose", "stdin", msgPath)
			f, err := os.Open(msgPath)
			if err != nil {
				log.Fatalf("%w", err)
			}
			cmd.Stdin = f
			return Scenario{cmd: cmd, cleanup: func() { f.Close() }}
		}())
	}

	cmds.ParallelRun()

	exec.Command("run_local_hook", append([]string{"commit-msg"}, os.Args[1:]...)...).CombinedOutput()
}

type Scenario struct {
	cmd     *exec.Cmd
	cleanup func()
}

type Scenarios []Scenario

func (cmds Scenarios) ParallelRun() {
	wg := &sync.WaitGroup{}
	for _, cmd := range cmds {
		wg.Add(1)
		go func(scenario Scenario) {
			defer wg.Done()
			defer scenario.cleanup()
			cmd := scenario.cmd
			output, err := cmd.CombinedOutput()
			log.Println(strings.Join(cmd.Args, " "))
			log.Println(string(output))
			if err != nil {
				log.Fatalln(err)
			}
		}(cmd)
	}
	wg.Wait()
}

package runner

import (
	"log"
	"os/exec"
	"strings"
	"sync"
)

type Cmd struct {
	Path string
	Args []string
}

type Commands []Cmd

// Why not external display-width libraries:
// Command arguments logged here are file paths and flags where character count is enough,
// avoiding external Unicode table dependencies in go.mod.
func truncateArgs(args []string) string {
	s := strings.Join(args, " ")
	runes := []rune(s)
	if len(runes) <= 60 {
		return s
	}
	return string(runes[:57]) + "..."
}

func (cmds Commands) ParallelRun() {
	wg := new(sync.WaitGroup)
	for _, cmd := range cmds {
		wg.Go(func() {
			output, err := exec.Command(cmd.Path, cmd.Args...).CombinedOutput()
			log.Printf("%s %s\n%s\n", cmd.Path, truncateArgs(cmd.Args), string(output))
			if err != nil {
				log.Fatalln(err)
			}
		})
	}
	wg.Wait()
}

func (cmds Commands) SequentialRun() {
	for _, cmd := range cmds {
		output, err := exec.Command(cmd.Path, cmd.Args...).CombinedOutput()
		log.Printf("%s %s\n%s\n", cmd.Path, truncateArgs(cmd.Args), string(output))
		if err != nil {
			log.Fatalln(err)
		}
	}
}

package runner

import (
	"log"
	"os/exec"
	"strings"
	"sync"

	"github.com/mattn/go-runewidth"
)

type Cmd struct {
	Path string
	Args []string
}

type Commands []Cmd

func (cmds Commands) ParallelRun() {
	wg := &sync.WaitGroup{}
	for _, cmd := range cmds {
		wg.Add(1)
		go func(cmd Cmd) {
			defer wg.Done()
			output, err := exec.Command(cmd.Path, cmd.Args...).CombinedOutput()
			log.Printf("%s %s\n%s\n", cmd.Path, runewidth.Truncate(strings.Join(cmd.Args, " "), 60, "..."), string(output))
			if err != nil {
				log.Fatalln(err)
			}
		}(cmd)
	}
	wg.Wait()
}

func (cmds Commands) SequentialRun() {
	for _, cmd := range cmds {
		output, err := exec.Command(cmd.Path, cmd.Args...).CombinedOutput()
		log.Printf("%s %s\n%s\n", cmd.Path, runewidth.Truncate(strings.Join(cmd.Args, " "), 60, ""), string(output))
		if err != nil {
			log.Fatalln(err)
		}
	}
}

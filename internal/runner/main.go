package runner

import (
	"errors"
	"fmt"
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

func (cmds Commands) ParallelRun() error {
	type result struct {
		output []byte
		err    error
	}

	results := make([]result, len(cmds))
	var wg sync.WaitGroup
	for i, cmd := range cmds {
		wg.Go(func() {
			output, err := exec.Command(cmd.Path, cmd.Args...).CombinedOutput()
			results[i] = result{output: output, err: err}
		})
	}
	wg.Wait()

	var errs []error
	for i, cmd := range cmds {
		res := results[i]
		log.Printf("%s %s\n%s\n", cmd.Path, truncateArgs(cmd.Args), string(res.output))
		if res.err != nil {
			errs = append(errs, fmt.Errorf("%s: %w", cmd.Path, res.err))
		}
	}
	return errors.Join(errs...)
}

func (cmds Commands) SequentialRun() error {
	for _, cmd := range cmds {
		output, err := exec.Command(cmd.Path, cmd.Args...).CombinedOutput()
		log.Printf("%s %s\n%s\n", cmd.Path, truncateArgs(cmd.Args), string(output))
		if err != nil {
			return fmt.Errorf("%s: %w", cmd.Path, err)
		}
	}
	return nil
}

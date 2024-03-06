//go:build windows

package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/kachick/dotfiles/internal/windows"
)

func usage() string {
	return `Usage: winit-reg [SUB] [OPTIONS]

Windows initialization to modify default settings

$ winit-reg list
$ winit-reg run --action disable_beeps
$ winit-reg run --all
`
}

var funcByAction = map[string]func(){
	"enable_long_path":            windows.EnableLongPath,
	"regain_verbose_context_menu": windows.RegainVerboseContextMenu,
	"disable_beeps":               windows.DisableBeeps,
}

func printActions() {
	fmt.Println(`Supported actions:`)

	for action, _ := range funcByAction {
		fmt.Printf("  - %s\n", action)
	}
}

// # https://github.com/kachick/times_kachick/issues/214
func main() {
	runCmd := flag.NewFlagSet("run", flag.ExitOnError)
	actionFlag := runCmd.String("action", "", "which action you want to do")
	allFlag := runCmd.Bool("all", false, "do ALL if you trust me")

	switch os.Args[1] {
	case "list":
		// TODO: prints current settings

		printActions()
	case "run":
		err := runCmd.Parse(os.Args[2:])
		if err != nil {
			flag.Usage()
		}

		if *allFlag {
			if *actionFlag != "" {
				log.Fatalln("Specify either --all or one --action, not both together")
			}

			for action, f := range funcByAction {
				log.Println(action)
				f()
			}

			return
		}

		f, known := funcByAction[*actionFlag]
		if !known {
			printActions()
			os.Exit(1)
		}
		f()
	default:
		flag.Usage()

		os.Exit(1)
	}
}

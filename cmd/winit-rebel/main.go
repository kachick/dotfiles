//go:build windows

package main

import (
	"flag"
	"log"
	"os"

	"github.com/kachick/dotfiles/internal/windows"
)

func usage() string {
	return `Usage: winit-rebel [SUB] [OPTIONS]

Windows initialization to modify default settings

$ winit-rebel list
$ winit-rebel run --action disable_beeps
$ winit-rebel run --action regain_verbose_context_menu
$ winit-rebel run --all
`
}

func printActions() {
	log.Println("supported actions:")
	log.Println("disable_beeps")
	log.Println("regain_verbose_context_menu")
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

			windows.DisableBeep()
			windows.RegainVerboseContextMenu()

			return
		}

		switch *actionFlag {
		case "disable_beeps":
			{
				windows.DisableBeep()
			}
		case "regain_verbose_context_menu":
			{
				windows.RegainVerboseContextMenu()
			}
		default:
			printActions()

			os.Exit(1)
		}
	default:
		flag.Usage()

		os.Exit(1)
	}
}

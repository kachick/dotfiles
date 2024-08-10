package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
)

func main() {
	wdirFlag := flag.String("wd", ".", "working directory")

	flag.Parse()

	workingDirectory := *wdirFlag
	var queries []string

	if len(os.Args) > 1 {
		queries = os.Args[1:]
	} else {
		queries = []string{}
	}

	// println(os.Args)

	// Using golang to handle CLI flags. So omitting to translate pipe handling

	fdCmd := fmt.Sprintf("fd --type f --hidden --follow --exclude .git '%s'", workingDirectory)
	fzfCmd := fmt.Sprintf("fzf --query '%s' --preview 'bat --color=always {}' --preview-window ~3 --bind 'enter:become(command \"$EDITOR\" {})'", strings.Join(queries, " "))

	bytes, err := exec.Command("bash", "-c", strings.Join([]string{fdCmd, fzfCmd}, " | ")).CombinedOutput()
	if err != nil {
		log.Fatalln(err)
	}
	fmt.Println(string(bytes))
}

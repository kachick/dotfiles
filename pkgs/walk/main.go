package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/mattn/go-pipeline"
)

func main() {
	wdirFlag := flag.String("d", ".", "working directory")

	flag.Parse()

	workingDirectory := *wdirFlag
	var queries []string

	if len(os.Args) > 2 {
		queries = os.Args[2:]
	} else {
		queries = []string{}
	}

	// query := os.Args[2]

	// queries := []string{"l", "m"}

	// strings.Join(queries, " ")

	// fmt.Println(strings.Join(queries, " "))

	bytes, err := pipeline.CombinedOutput(
		[]string{
			"fd", "--type", "f", "--hidden", "--follow", "--exclude", ".git", ".", workingDirectory,
		},
		[]string{
			"fzf", "--query", strings.Join(queries, " "), "--preview", "bat --color=always {}", "--preview-window", "~3", "--bind", "enter:become(command \"$EDITOR\" {})",
		},
	)

	if err != nil {
		log.Fatalln(err)
	}

	fmt.Println(string(bytes))
}

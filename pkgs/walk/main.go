package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/mattn/go-pipeline"
)

func main() {
	wdirFlag := flag.String("d", ".", "working directory")

	flag.Parse()

	workingDirectory := *wdirFlag

	query := os.Args[1]
	// queries := os.Args[1:]
	// queries := []string{"l", "m"}

	// strings.Join(queries, " ")

	// fmt.Println(strings.Join(queries, " "))

	bytes, err := pipeline.CombinedOutput(
		[]string{
			"fd", "--type", "f", "--hidden", "--follow", "--exclude", ".git", ".", workingDirectory,
		},
		[]string{
			"fzf", "--query", query, "--preview", "bat --color=always {}", "--preview-window", "~3", "--bind", "enter:become(command \"$EDITOR\" {})",
		},
	)

	if err != nil {
		log.Fatalln(err)
	}

	fmt.Println(string(bytes))
}

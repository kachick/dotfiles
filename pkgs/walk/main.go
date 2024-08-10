package main

import (
	"flag"
	"fmt"
	"io"
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

	if len(os.Args) > 2 {
		queries = os.Args[2:]
	} else {
		queries = []string{}
	}

	fdCmd := exec.Command(
		"fd", "--type", "f", "--hidden", "--follow", "--exclude", ".git", ".", workingDirectory,
	)
	fzfCmd := exec.Command(
		"fzf", "--query", strings.Join(queries, " "), "--preview", "bat --color=always {}", "--preview-window", "~3", "--bind", "enter:become(command \"$EDITOR\" {})",
	)

	fdOut, err := fdCmd.StdoutPipe()
	if err != nil {
		log.Fatalln(err)
	}

	fzfOut, err := fzfCmd.StdoutPipe()
	if err != nil {
		log.Fatalln(err)
	}

	fzfCmd.Stdin = fdOut

	// Required to start following command first...?
	err = fzfCmd.Start()
	if err != nil {
		log.Fatalln(err)
	}
	err = fdCmd.Start()
	if err != nil {
		log.Fatalln(err)
	}

	// Readall looks not correct choice
	bytes, err := io.ReadAll(fzfOut)
	if err != nil {
		log.Fatalln(err)
	}

	err = fdCmd.Wait()
	if err != nil {
		log.Fatalln(err)
	}
	err = fzfCmd.Wait()
	if err != nil {
		log.Fatalln(err)
	}

	fmt.Println(string(bytes))
}

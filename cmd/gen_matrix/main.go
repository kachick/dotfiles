package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"strings"
)

type Matrix struct {
	Runner []string `json:"runner"`
}

func main() {
	eventNameFlag := flag.String("event_name", "", "github.event_name")
	pathsFlag := flag.String("paths", "", "changed paths specified by lines")

	flag.Parse()

	eventName := *eventNameFlag
	paths := *pathsFlag

	higherMacOSPossibility := false

	for paths != "" {
		line, rest, _ := strings.Cut(paths, "\n")
		paths = rest
		line = strings.TrimSuffix(line, "\r")

		if strings.Contains(line, "darwin") || line == ".github/workflows/ci-home.yml" || line == "home-manager/packages.nix" || line == "flake.nix" {
			higherMacOSPossibility = true
		}
	}

	if eventName == "" {
		flag.Usage()
		log.Fatalln("empty event_name is given")
	}

	matrix := Matrix{
		// https://github.com/actions/runner-images/issues/9741#issuecomment-2075259811
		Runner: []string{
			"ubuntu-24.04",
		},
	}

	if higherMacOSPossibility || eventName != "pull_request" {
		matrix.Runner = append(matrix.Runner,
			// Intel. Correct with the architecture. But basically skipping because of it is much slow to complete.
			"macos-13",
		)
	}

	bytes, err := json.MarshalIndent(matrix, "", "  ")
	if err != nil {
		log.Fatalln("can't marshal generated JSON matrix")
	}

	fmt.Println(string(bytes))
}

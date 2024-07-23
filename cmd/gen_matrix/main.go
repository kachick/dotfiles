package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
)

type Matrix struct {
	Os []string `json:"os"`
}

func main() {
	eventNameFlag := flag.String("event_name", "", "github.event_name")

	flag.Parse()

	eventName := *eventNameFlag

	if eventName == "" {
		flag.Usage()
		log.Fatalln("empty event_name is given")
	}

	matrix := Matrix{
		//  https://github.com/actions/runner-images/issues/9741#issuecomment-2075259811
		Os: []string{
			"ubuntu-24.04",
			//  M1. Doesn't match for my Intel Mac, but preferring for much faster.
			"macos-14",
		},
	}

	if eventName != "pull_request" {
		matrix.Os = append(matrix.Os,
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

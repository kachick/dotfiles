package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func extractRepo(line string) string {
	// Using Cut cannot handle `multiple sep as foo/bar/baz`, but I don't need to conisder it for `owner/repo` or `repo` patterns.
	_, after, found := strings.Cut(line, "/")
	if found {
		return after
	} else {
		return line
	}
}

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		line := scanner.Text()
		fmt.Println(extractRepo(line))
	}
}

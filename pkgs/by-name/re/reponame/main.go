package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

// Can't I use https://github.com/google/go-github or https://github.com/cli/cli for more robust feature?
// They are looks depend on GitHub API, not only for string operations...
func extractRepo(line string) string {
	base := strings.TrimPrefix(line, "git@github.com:")
	base = strings.TrimPrefix(base, "https://github.com/")
	base = strings.TrimSuffix(base, ".git")
	_, after, found := strings.CutLast(base, "/")
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

package main

import (
	"bufio"
	"fmt"
	"os"
	"strings"
)

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		line := scanner.Text()
		// Using Cut cannot handle `multiple sep as foo/bar/baz`, but I don't need to conisder it for `owner/repo` or `repo` patterns.
		_, after, found := strings.Cut(line, "/")
		if found {
			fmt.Println(after)
		} else {
			fmt.Println(line)
		}
	}
}

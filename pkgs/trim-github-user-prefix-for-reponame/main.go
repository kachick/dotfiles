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
		_, after, found := strings.Cut(line, "/")
		if found {
			fmt.Println(after)
		} else {
			fmt.Println(line)
		}
	}
}

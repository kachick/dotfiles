package main

import (
	"bufio"
	"flag"
	"fmt"
	"io"
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
	}
	return line
}

func runGhReponame(args []string, stdin io.Reader, stdout, stderr io.Writer) error {
	fs := flag.NewFlagSet("gitx gh-reponame", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: gitx gh-reponame\n\n")
		fmt.Fprintf(stderr, "Read repository specs or GitHub URLs from stdin and print the repository name.\n")
	}

	if err := fs.Parse(args); err != nil {
		return err
	}
	if len(fs.Args()) != 0 {
		fs.Usage()
		return fmt.Errorf("expected no positional arguments, got %d", len(fs.Args()))
	}

	scanner := bufio.NewScanner(stdin)
	for scanner.Scan() {
		fmt.Fprintln(stdout, extractRepo(scanner.Text()))
	}
	return scanner.Err()
}

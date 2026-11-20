package main

import (
	"errors"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

const (
	branchPrefix = "├── "
	indentPrefix = "│   "
)

func main() {
	os.Exit(run(os.Args[1:], os.Stdin, os.Stdout, os.Stderr))
}

func run(args []string, stdin io.Reader, stdout, stderr io.Writer) int {
	var showAll bool
	fs := flag.NewFlagSet("tree-diff", flag.ContinueOnError)
	fs.SetOutput(stderr)
	fs.BoolVar(&showAll, "a", false, "include hidden entries starting with '.'")
	fs.BoolVar(&showAll, "all", false, "include hidden entries starting with '.'")
	fs.Usage = func() {
		fmt.Fprintf(stderr, "Usage: tree-diff [-a|--all] <dirA> <dirB>\n\n")
		fmt.Fprintf(stderr, "Compare directory trees with a normalized diff-friendly layout.\n\n")
		fs.PrintDefaults()
	}

	if err := fs.Parse(args); err != nil {
		if errors.Is(err, flag.ErrHelp) {
			return 0
		}
		return 2
	}

	if fs.NArg() != 2 {
		fs.Usage()
		return 2
	}

	dirA := fs.Arg(0)
	dirB := fs.Arg(1)

	for _, dir := range []string{dirA, dirB} {
		info, err := os.Stat(dir)
		if err != nil {
			fmt.Fprintf(stderr, "Error: %v\n", err)
			fs.Usage()
			return 2
		}
		if !info.IsDir() {
			fmt.Fprintf(stderr, "Error: %s is not a directory\n", dir)
			fs.Usage()
			return 2
		}
	}

	exitCode, err := runTreeDiff(dirA, dirB, showAll, stdin, stdout, stderr)
	if err != nil {
		fmt.Fprintf(stderr, "Error: %v\n", err)
		return 2
	}
	return exitCode
}

func runTreeDiff(dirA, dirB string, showAll bool, stdin io.Reader, stdout, stderr io.Writer) (int, error) {
	treeA, err := renderNormalizedTree(dirA, showAll)
	if err != nil {
		return 2, fmt.Errorf("render tree for %s: %w", dirA, err)
	}
	treeB, err := renderNormalizedTree(dirB, showAll)
	if err != nil {
		return 2, fmt.Errorf("render tree for %s: %w", dirB, err)
	}

	tmpDir, err := os.MkdirTemp("", "tree-diff-*")
	if err != nil {
		return 2, fmt.Errorf("create temp dir: %w", err)
	}
	defer os.RemoveAll(tmpDir)

	fileA := filepath.Join(tmpDir, "a")
	fileB := filepath.Join(tmpDir, "b")
	if err := os.WriteFile(fileA, []byte(treeA), 0o600); err != nil {
		return 2, fmt.Errorf("write temp file: %w", err)
	}
	if err := os.WriteFile(fileB, []byte(treeB), 0o600); err != nil {
		return 2, fmt.Errorf("write temp file: %w", err)
	}

	cmd := exec.Command("git", "diff", "--no-index", "--", "a", "b")
	cmd.Dir = tmpDir
	cmd.Stdin = stdin
	cmd.Stdout = stdout
	cmd.Stderr = stderr
	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			return exitErr.ExitCode(), nil
		}
		return 2, fmt.Errorf("run git diff: %w", err)
	}
	return 0, nil
}

func renderNormalizedTree(rootDir string, showAll bool) (string, error) {
	var b strings.Builder
	// Print "." at the top so comparing two different directory paths avoids a noisy root header diff.
	b.WriteString(".\n")
	if err := walkNormalizedTree(&b, rootDir, "", showAll); err != nil {
		return "", err
	}
	return b.String(), nil
}

func walkNormalizedTree(b *strings.Builder, dirPath, prefix string, showAll bool) error {
	entries, err := os.ReadDir(dirPath)
	if err != nil {
		return err
	}

	for _, entry := range entries {
		name := entry.Name()
		if !showAll && strings.HasPrefix(name, ".") {
			continue
		}

		fullPath := filepath.Join(dirPath, name)

		// Check symlinks before directories so symlinked directories do not cause loops.
		if entry.Type()&os.ModeSymlink != 0 {
			target, err := os.Readlink(fullPath)
			if err != nil {
				return err
			}
			fmt.Fprintf(b, "%s%s%s -> %s\n", prefix, branchPrefix, name, target)
			continue
		}

		if entry.IsDir() {
			fmt.Fprintf(b, "%s%s%s/\n", prefix, branchPrefix, name)
			// Use "│   " even for the last directory so adding a sibling later never shifts child indentation.
			if err := walkNormalizedTree(b, fullPath, prefix+indentPrefix, showAll); err != nil {
				return err
			}
			continue
		}

		fmt.Fprintf(b, "%s%s%s\n", prefix, branchPrefix, name)
	}

	return nil
}

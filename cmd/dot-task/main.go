package main

import (
	"fmt"
	"io"
	"os"
	"os/exec"
)

type env struct {
	stdin      io.Reader
	stdout     io.Writer
	stderr     io.Writer
	runCmd     func(name string, args ...string) error
	cmdOutput  func(name string, args ...string) ([]byte, error)
	cmdExitOK  func(name string, args ...string) (bool, error)
	selectItem func(items []string, prompt, header string) (string, error)
	isTerminal func() bool
	fileExists func(path string) bool
	hostname   func() (string, error)
	getenv     func(key string) string
}

func isCharDevice(f *os.File) bool {
	if f == nil {
		return false
	}
	info, err := f.Stat()
	if err != nil {
		return false
	}
	return (info.Mode() & os.ModeCharDevice) != 0
}

func defaultEnv() env {
	return env{
		stdin:  os.Stdin,
		stdout: os.Stdout,
		stderr: os.Stderr,
		runCmd: func(name string, args ...string) error {
			cmd := exec.Command(name, args...)
			cmd.Stdin = os.Stdin
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			return cmd.Run()
		},
		cmdOutput: func(name string, args ...string) ([]byte, error) {
			cmd := exec.Command(name, args...)
			cmd.Stderr = os.Stderr
			return cmd.Output()
		},
		cmdExitOK: func(name string, args ...string) (bool, error) {
			cmd := exec.Command(name, args...)
			err := cmd.Run()
			if err == nil {
				return true, nil
			}
			if _, ok := err.(*exec.ExitError); ok {
				return false, nil
			}
			return false, err
		},
		selectItem: func(items []string, prompt, header string) (string, error) {
			return selectWithFzf(items, prompt, header, os.Stderr)
		},
		isTerminal: func() bool {
			return isCharDevice(os.Stdin) && isCharDevice(os.Stderr)
		},
		fileExists: func(path string) bool {
			_, err := os.Stat(path)
			return err == nil
		},
		hostname: os.Hostname,
		getenv:   os.Getenv,
	}
}

func main() {
	if err := run(os.Args[1:], defaultEnv()); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

func run(args []string, e env) error {
	if len(args) < 1 {
		return fmt.Errorf("usage: dot-task <apply|nixos|home-manager|update|ghcr> [args]")
	}

	subcommand := args[0]
	rest := args[1:]
	switch subcommand {
	case "apply":
		return runApply(rest, e)
	case "nixos":
		return runNixos(rest, e)
	case "home-manager":
		return runHomeManager(rest, e)
	case "update":
		return runUpdate(rest, e)
	case "ghcr":
		return runGHCR(rest, e)
	default:
		return fmt.Errorf("unknown subcommand %q (usage: dot-task <apply|nixos|home-manager|update|ghcr> [args])", subcommand)
	}
}

package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"time"
)

type env struct {
	stdin                 io.Reader
	stdout                io.Writer
	stderr                io.Writer
	runCmd                func(name string, args ...string) error
	cmdOutput             func(name string, args ...string) ([]byte, error)
	cmdCombinedOutput     func(name string, args ...string) ([]byte, error)
	cmdExitOK             func(name string, args ...string) (bool, error)
	selectItem            func(items []string, prompt, header string) (string, error)
	selectItemWithOptions func(items []string, opts fzfOptions) (string, error)
	isTerminal            func() bool
	fileExists            func(path string) bool
	hostname              func() (string, error)
	getenv                func(key string) string
	now                   func() time.Time
	cacheDir              func() (string, error)
	executable            func() (string, error)
	httpClient            *http.Client
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
		cmdCombinedOutput: func(name string, args ...string) ([]byte, error) {
			cmd := exec.Command(name, args...)
			return cmd.CombinedOutput()
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
		selectItemWithOptions: func(items []string, opts fzfOptions) (string, error) {
			return selectWithFzfOptions(items, opts, os.Stderr)
		},
		isTerminal: func() bool {
			return isCharDevice(os.Stdin) && isCharDevice(os.Stderr)
		},
		fileExists: func(path string) bool {
			_, err := os.Stat(path)
			return err == nil
		},
		hostname:   os.Hostname,
		getenv:     os.Getenv,
		now:        time.Now,
		cacheDir:   os.UserCacheDir,
		executable: os.Executable,
		httpClient: &http.Client{Timeout: 30 * time.Second},
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
		return fmt.Errorf("usage: dot-task <apply|nixos|home-manager|check-nixos|update|ghcr> [args]")
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
	case "check-nixos":
		return runCheckNixos(rest, e)
	case "update":
		return runUpdate(rest, e)
	case "ghcr":
		return runGHCR(rest, e)
	case "ghcr-preview":
		return runGHCRPreview(rest, e)
	default:
		return fmt.Errorf("unknown subcommand %q (usage: dot-task <apply|nixos|home-manager|check-nixos|update|ghcr> [args])", subcommand)
	}
}

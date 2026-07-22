package main

import (
	"bufio"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"strings"
)

func main() {
	configPath := os.Getenv("IBUS_CONFIG_TEXTPROTO")
	if configPath == "" {
		log.Fatal("IBUS_CONFIG_TEXTPROTO is not set. Please provide it via environment variable or use a version built with Nix.")
	}

	f, err := os.Open(configPath)
	if err != nil {
		log.Fatalf("Error opening config (%s): %v", configPath, err)
	}
	defer f.Close()

	engines, err := parseConfig(f)
	if err != nil {
		log.Fatalf("Error parsing config: %v", err)
	}

	var options []string
	for _, e := range engines {
		options = append(options, fmt.Sprintf("%-20s # Mozc (%s)", e.name, e.longname))
	}
	options = append(options, "xkb:us::eng           # Typically disable Mozc (ANSI)")
	options = append(options, "xkb:us::jpn           # Typically disable Mozc (JIS)")

	selected, err := runFzf(options)
	if err != nil {
		// fzf returns 130 when cancelled with Esc/Ctrl-C
		if exitErr, ok := err.(*exec.ExitError); ok && exitErr.ExitCode() == 130 {
			os.Exit(0)
		}
		log.Fatalf("Error running fzf: %v", err)
	}

	engineName := strings.Fields(selected)[0]
	fmt.Printf("Switching to %s...\n", engineName)
	if err := runIbus(engineName); err != nil {
		log.Fatalf("Error running ibus: %v", err)
	}
}

func parseConfig(r io.Reader) ([]engine, error) {
	var engines []engine
	var current engine
	scanner := bufio.NewScanner(r)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		if strings.HasPrefix(line, "name :") {
			current.name = strings.Trim(strings.Split(line, ":")[1], " \"")
		}
		if strings.HasPrefix(line, "longname :") {
			current.longname = strings.Trim(strings.Split(line, ":")[1], " \"")
		}
		if line == "}" && current.name != "" {
			engines = append(engines, current)
			current = engine{}
		}
	}
	return engines, scanner.Err()
}

type engine struct {
	name     string
	longname string
}

func runFzf(options []string) (string, error) {
	cmd := exec.Command("fzf", "--prompt=Select iBus engine: ", "--height=40%", "--reverse", "--ansi")
	cmd.Stdin = strings.NewReader(strings.Join(options, "\n"))
	cmd.Stderr = os.Stderr
	out, err := cmd.Output()
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

func runIbus(engine string) error {
	return exec.Command("ibus", "engine", engine).Run()
}

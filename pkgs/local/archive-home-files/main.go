package main

import (
	"bytes"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
)

func main() {
	var (
		gitleaksConfig string
		ageRecipients  string
	)

	// Prefer flags, then environment variables
	flag.StringVar(&gitleaksConfig, "gitleaks-config", os.Getenv("GITLEAKS_CONFIG"), "Path to gitleaks config file")
	flag.StringVar(&ageRecipients, "age-recipients", os.Getenv("AGE_RECIPIENTS"), "Comma separated age recipients")
	flag.Parse()

	if flag.NArg() < 1 {
		fmt.Printf("Usage: %s [options] <archive_basename>\n", os.Args[0])
		flag.PrintDefaults()
		os.Exit(1)
	}
	archiveBasename := flag.Arg(0)

	if gitleaksConfig == "" {
		fmt.Fprintf(os.Stderr, "Error: GITLEAKS_CONFIG is not set. Use -gitleaks-config flag or set GITLEAKS_CONFIG environment variable.\n")
		os.Exit(1)
	}
	if ageRecipients == "" {
		fmt.Fprintf(os.Stderr, "Error: AGE_RECIPIENTS is not set. Use -age-recipients flag or set AGE_RECIPIENTS environment variable.\n")
		os.Exit(1)
	}

	fmt.Printf("Step 1: Resolving home-manager generation path...\n")
	hmPath, err := resolveHMPath()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error resolving HM path: %v\n", err)
		os.Exit(1)
	}
	homeFilesPath := filepath.Join(hmPath, "home-files")
	fmt.Printf("Resolved home-files path: %s\n", homeFilesPath)

	if _, err := os.Stat(homeFilesPath); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "Error: home-files directory does not exist: %s\n", homeFilesPath)
		os.Exit(1)
	}

	fmt.Printf("\nStep 2: Running gitleaks check...\n")
	if err := runGitleaks(homeFilesPath, gitleaksConfig); err != nil {
		fmt.Fprintf(os.Stderr, "Gitleaks check failed: %v\n", err)
		os.Exit(1)
	}

	tarFile := archiveBasename + ".tar.gz"
	fmt.Printf("\nStep 3: Creating tarball: %s\n", tarFile)
	if err := createTarball(homeFilesPath, tarFile); err != nil {
		fmt.Fprintf(os.Stderr, "Tarball creation failed: %v\n", err)
		os.Exit(1)
	}

	ageFile := tarFile + ".age"
	fmt.Printf("\nStep 4: Encrypting with age: %s\n", ageFile)
	if err := encryptWithAge(tarFile, ageFile, ageRecipients); err != nil {
		fmt.Fprintf(os.Stderr, "Encryption failed: %v\n", err)
		os.Exit(1)
	}

	if err := os.Remove(tarFile); err != nil {
		fmt.Fprintf(os.Stderr, "Warning: Failed to remove temporary tarball %s: %v\n", tarFile, err)
	}

	fmt.Printf("\nSuccessfully created encrypted archive: %s\n", ageFile)
}

func resolveHMPath() (string, error) {
	cmd := exec.Command("home-manager", "generations")
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("failed to run 'home-manager generations': %w", err)
	}

	// Regex to match: id 181 -> /nix/store/...-home-manager-generation
	re := regexp.MustCompile(`id \d+ -> (/nix/store/[^ ]+)`)
	lines := strings.Split(strings.TrimSpace(out.String()), "\n")
	if len(lines) == 0 || lines[0] == "" {
		return "", fmt.Errorf("no output from 'home-manager generations'")
	}

	// First line is the latest generation
	match := re.FindStringSubmatch(lines[0])
	if len(match) < 2 {
		return "", fmt.Errorf("could not parse generation path from: %s", lines[0])
	}

	return match[1], nil
}

func runGitleaks(source, config string) error {
	// 'dir' is the modern command to scan directories without git context
	args := []string{"dir", source, "--config", config, "--follow-symlinks", "--verbose", "--redact=100"}
	cmd := exec.Command("gitleaks", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("gitleaks detected secrets or failed: %w", err)
	}
	return nil
}

func createTarball(source, output string) error {
	// Using external tar command for easy symlink dereferencing
	args := []string{"--create", "--file=" + output, "--auto-compress", "--dereference", "--recursive", "--directory=" + source, "."}
	cmd := exec.Command("tar", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("tar failed: %w", err)
	}
	return nil
}

func encryptWithAge(source, output, recipientsStr string) error {
	recipients := strings.Split(recipientsStr, ",")
	args := []string{}
	for _, r := range recipients {
		if r == "" {
			continue
		}
		args = append(args, "--recipient", r)
	}
	// Use -- to ensure source is not treated as a flag even if it starts with -
	args = append(args, "--output", output, "--", source)

	cmd := exec.Command("age", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("age failed: %w", err)
	}
	return nil
}

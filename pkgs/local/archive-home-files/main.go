package main

import (
	"bytes"
	"crypto/rand"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"time"
)

func main() {
	var (
		betterleaksConfig string
		ageRecipients  string
	)

	// Prefer flags, then environment variables
	flag.StringVar(&betterleaksConfig, "betterleaks-config", os.Getenv("BETTERLEAKS_CONFIG"), "Path to betterleaks config file")
	flag.StringVar(&ageRecipients, "age-recipients", os.Getenv("AGE_RECIPIENTS"), "Comma separated age recipients")
	flag.Parse()

	var archiveBasename string
	if flag.NArg() < 1 {
		// Default to a timestamp-based name with random suffix if no argument is provided
		randomSuffix, err := generateRandomString(4)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error generating random suffix: %v\n", err)
			os.Exit(1)
		}
		archiveBasename = fmt.Sprintf("home-files-%s-%s", time.Now().Format("20060102-150405"), randomSuffix)
		fmt.Printf("No archive name provided. Using default: %s\n", archiveBasename)
	} else {
		archiveBasename = flag.Arg(0)
	}

	if betterleaksConfig == "" {
		fmt.Fprintf(os.Stderr, "Error: BETTERLEAKS_CONFIG is not set. Use -betterleaks-config flag or set BETTERLEAKS_CONFIG environment variable.\n")
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

	// Create a temporary directory for the intermediate tarball
	tmpDir, err := os.MkdirTemp("", "archive-home-files-")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating temporary directory: %v\n", err)
		os.Exit(1)
	}
	defer os.RemoveAll(tmpDir)

	tarFile := filepath.Join(tmpDir, "intermediate.tar.gz")
	fmt.Printf("\nStep 2: Creating temporary tarball for scanning...\n")
	if err := createTarball(homeFilesPath, tarFile); err != nil {
		fmt.Fprintf(os.Stderr, "Tarball creation failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("\nStep 3: Running betterleaks check on the generated archive...\n")
	if err := runBetterleaksOnArchive(tarFile, betterleaksConfig); err != nil {
		fmt.Fprintf(os.Stderr, "Betterleaks check failed: %v\n", err)
		os.Exit(1)
	}

	ageFile := archiveBasename + ".tar.gz.age"
	fmt.Printf("\nStep 4: Encrypting with age: %s\n", ageFile)
	if err := encryptWithAge(tarFile, ageFile, ageRecipients); err != nil {
		fmt.Fprintf(os.Stderr, "Encryption failed: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("\nSuccessfully created encrypted archive: %s\n", ageFile)
}

func generateRandomString(n int) (string, error) {
	const charset = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, n)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	var result strings.Builder
	for _, v := range b {
		result.WriteByte(charset[int(v)%len(charset)])
	}
	return result.String(), nil
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

func runBetterleaksOnArchive(archivePath, config string) error {
	// Scan inside the archive by setting --max-archive-depth=1.
	// This is more reliable than scanning symlinked directories.
	args := []string{"dir", archivePath, "--config", config, "--max-archive-depth=1", "--verbose", "--redact=100"}
	cmd := exec.Command("betterleaks", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("betterleaks detected secrets in archive or failed: %w", err)
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

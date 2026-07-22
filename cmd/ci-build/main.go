package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Usage: ci-build <package|nixos> [options] [args]")
		os.Exit(1)
	}

	subcommand := os.Args[1]
	switch subcommand {
	case "package":
		if err := runPackage(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	case "nixos":
		if err := runNixos(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	default:
		fmt.Fprintf(os.Stderr, "Unknown subcommand: %s\nUsage: ci-build <package|nixos> [options] [args]\n", subcommand)
		os.Exit(1)
	}
}

func getCurrentNixSystem() (string, error) {
	cmd := exec.Command("nix", "eval", "--raw", "--impure", "--expr", "builtins.currentSystem")
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("failed to detect current Nix system: %w", err)
	}
	system := strings.TrimSpace(out.String())
	if system == "" {
		return "", fmt.Errorf("current Nix system output was empty")
	}
	return system, nil
}

func runPackage(args []string) error {
	fs := flag.NewFlagSet("package", flag.ExitOnError)
	archFlag := fs.String("arch", "", "Target system architecture (defaults to nix builtins.currentSystem)")
	skipTests := fs.Bool("skip-tests", false, "Skip running passthru.tests")

	if err := fs.Parse(args); err != nil {
		return err
	}

	if fs.NArg() < 1 {
		return fmt.Errorf("package name is required")
	}

	pname := fs.Arg(0)
	arch := *archFlag
	if arch == "" {
		detectedArch, err := getCurrentNixSystem()
		if err != nil {
			return err
		}
		arch = detectedArch
	}

	buildTarget := fmt.Sprintf(".#%s", pname)
	buildCmd := exec.Command("nix", "build", buildTarget, "--no-link", "--show-trace")
	buildCmd.Stdout = os.Stdout
	buildCmd.Stderr = os.Stderr
	if err := buildCmd.Run(); err != nil {
		return err
	}

	if *skipTests {
		fmt.Printf("Skipping tests for %s as requested.\n", pname)
		return nil
	}

	evalTarget := fmt.Sprintf(".#%s.passthru.tests", pname)
	evalCmd := exec.Command("nix", "eval", evalTarget)
	if err := evalCmd.Run(); err != nil {
		fmt.Printf("No passthru.tests found for %s, skipping.\n", pname)
		return nil
	}

	testAttr := fmt.Sprintf("packages.%s.%s.passthru.tests", arch, pname)
	testCmd := exec.Command("nix-build", "--attr", testAttr)
	testCmd.Stdout = os.Stdout
	testCmd.Stderr = os.Stderr
	if err := testCmd.Run(); err != nil {
		return err
	}

	return nil
}

func runNixos(args []string) error {
	fs := flag.NewFlagSet("nixos", flag.ExitOnError)
	if err := fs.Parse(args); err != nil {
		return err
	}

	if fs.NArg() < 1 {
		return fmt.Errorf("host name is required")
	}

	host := fs.Arg(0)

	buildTarget := fmt.Sprintf(".#nixosConfigurations.%s.config.system.build.toplevel", host)
	buildCmd := exec.Command("nix", "build", buildTarget, "--no-link", "--show-trace")

	var errBuffer bytes.Buffer
	writer := io.MultiWriter(os.Stderr, &errBuffer)
	buildCmd.Stdout = os.Stdout
	buildCmd.Stderr = writer

	if err := buildCmd.Run(); err != nil {
		return err
	}

	// Evaluate NixOS module warnings directly instead of parsing CLI stderr logs
	evalTarget := fmt.Sprintf(".#nixosConfigurations.%s.config.warnings", host)
	evalCmd := exec.Command("nix", "eval", "--json", evalTarget)
	var evalOut bytes.Buffer
	evalCmd.Stdout = &evalOut
	evalCmd.Stderr = os.Stderr

	if err := evalCmd.Run(); err == nil {
		var warnings []string
		if err := json.Unmarshal(evalOut.Bytes(), &warnings); err == nil && len(warnings) > 0 {
			return fmt.Errorf("❌ NixOS evaluation warnings detected: %s", strings.Join(warnings, "; "))
		}
	}

	return nil
}

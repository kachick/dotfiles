package main

import (
	"bytes"
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

func runBuildAndCheckWarnings(name string, cmd *exec.Cmd) error {
	var errBuffer bytes.Buffer
	writer := io.MultiWriter(os.Stderr, &errBuffer)

	cmd.Stdout = os.Stdout
	cmd.Stderr = writer

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("command execution failed for %s: %w", name, err)
	}

	if strings.Contains(strings.ToLower(errBuffer.String()), "warning:") {
		return fmt.Errorf("❌ Nix evaluation warnings detected in %s!", name)
	}

	return nil
}

func runPackage(args []string) error {
	fs := flag.NewFlagSet("package", flag.ExitOnError)
	arch := fs.String("arch", "x86_64-linux", "Target system architecture")
	skipTests := fs.Bool("skip-tests", false, "Skip running passthru.tests")

	if err := fs.Parse(args); err != nil {
		return err
	}

	if fs.NArg() < 1 {
		return fmt.Errorf("package name is required")
	}

	pname := fs.Arg(0)
	fmt.Printf("Building package: %s (%s)\n", pname, *arch)

	buildTarget := fmt.Sprintf(".#%s", pname)
	buildCmd := exec.Command("nix", "build", buildTarget, "--no-link", "--show-trace")
	if err := runBuildAndCheckWarnings(pname, buildCmd); err != nil {
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

	testAttr := fmt.Sprintf("packages.%s.%s.passthru.tests", *arch, pname)
	testCmd := exec.Command("nix-build", "--attr", testAttr)
	testCmd.Stdout = os.Stdout
	testCmd.Stderr = os.Stderr
	if err := testCmd.Run(); err != nil {
		return fmt.Errorf("passthru.tests failed for %s: %w", pname, err)
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
	fmt.Printf("Building NixOS configuration: %s\n", host)

	buildTarget := fmt.Sprintf(".#nixosConfigurations.%s.config.system.build.toplevel", host)
	buildCmd := exec.Command("nix", "build", buildTarget, "--no-link", "--show-trace")
	return runBuildAndCheckWarnings(host, buildCmd)
}

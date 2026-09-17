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

	isFree, err := isPackageFree(pname, arch)
	if err != nil {
		return fmt.Errorf("checking license for %s: %w", pname, err)
	}

	buildTarget := fmt.Sprintf(".#%s", pname)
	var outBuf bytes.Buffer
	buildArgs := []string{"build", buildTarget, "--no-link", "--print-out-paths", "--show-trace"}
	var buildEnv []string

	if !isFree {
		// Only unfree packages require --impure and NIXPKGS_ALLOW_UNFREE=1.
		buildArgs = append(buildArgs, "--impure")
		buildEnv = append(os.Environ(), "NIXPKGS_ALLOW_UNFREE=1")
	}

	buildCmd := exec.Command("nix", buildArgs...)
	if len(buildEnv) > 0 {
		buildCmd.Env = buildEnv
	}
	buildCmd.Stdout = io.MultiWriter(os.Stdout, &outBuf)
	buildCmd.Stderr = os.Stderr
	if err := buildCmd.Run(); err != nil {
		return err
	}

	if *skipTests {
		fmt.Printf("Skipping tests for %s as requested.\n", pname)
	} else {
		evalTarget := fmt.Sprintf(".#%s.passthru.tests", pname)
		evalArgs := []string{"eval", evalTarget}
		if !isFree {
			evalArgs = append(evalArgs, "--impure")
		}
		evalCmd := exec.Command("nix", evalArgs...)
		if !isFree {
			evalCmd.Env = append(os.Environ(), "NIXPKGS_ALLOW_UNFREE=1")
		}
		if err := evalCmd.Run(); err != nil {
			fmt.Printf("No passthru.tests found for %s, skipping.\n", pname)
		} else {
			testAttr := fmt.Sprintf("packages.%s.%s.passthru.tests", arch, pname)
			testCmd := exec.Command("nix-build", "--attr", testAttr)
			if !isFree {
				testCmd.Env = append(os.Environ(), "NIXPKGS_ALLOW_UNFREE=1")
			}
			testCmd.Stdout = os.Stdout
			testCmd.Stderr = os.Stderr
			if err := testCmd.Run(); err != nil {
				return err
			}
		}
	}

	outPaths := strings.Fields(outBuf.String())
	if err := maybePushToCachix(pname, isFree, outPaths); err != nil {
		return err
	}

	return nil
}

func isPackageFree(pname string, arch string) (bool, error) {
	repoRootBytes, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		return false, fmt.Errorf("failed to detect repository root: %w", err)
	}
	repoRoot := strings.TrimSpace(string(repoRootBytes))

	expr := fmt.Sprintf(`
let
  flake = builtins.getFlake "%s";
  pkgs = flake.inputs.nixpkgs.legacyPackages.%s;
  lib = pkgs.lib;
  pkg = flake.packages.%s.%s;
  licenses = pkg.meta.license or lib.licenses.free;
in
if lib.isAttrs licenses && licenses ? "licenseType" then
  lib.licenses.isFree licenses
else if lib.isAttrs licenses then
  licenses.free or true
else if lib.isString licenses then
  true
else
  lib.all (l: l.free or true) licenses
`, repoRoot, arch, arch, pname)

	cmd := exec.Command("nix", "eval", "--impure", "--expr", expr)
	cmd.Env = append(os.Environ(), "NIXPKGS_ALLOW_UNFREE=1")
	out, err := cmd.Output()
	if err != nil {
		return false, fmt.Errorf("failed to evaluate license for %s: %w", pname, err)
	}
	result := strings.TrimSpace(string(out))
	switch result {
	case "true":
		return true, nil
	case "false":
		return false, nil
	default:
		return false, fmt.Errorf("unexpected license evaluation result for %s: %s", pname, result)
	}
}

func maybePushToCachix(pname string, isFree bool, outPaths []string) error {
	if !isFree {
		fmt.Printf("Skipping Cachix push for unfree package: %s\n", pname)
		return nil
	}

	if len(outPaths) == 0 {
		return fmt.Errorf("no output paths to push for %s", pname)
	}

	args := append([]string{"push", "kachick-dotfiles"}, outPaths...)
	fmt.Printf("Pushing %s to Cachix (%d paths)...\n", pname, len(outPaths))
	cmd := exec.Command("cachix", args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	return cmd.Run()
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
	buildCmd.Stdout = os.Stdout
	buildCmd.Stderr = os.Stderr

	return buildCmd.Run()
}

package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Usage: ci-build <package|packages|nixos|sync-workflows> [options] [args]")
		os.Exit(1)
	}

	subcommand := os.Args[1]
	switch subcommand {
	case "package":
		if err := runPackage(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	case "packages":
		if err := runPackages(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	case "nixos":
		if err := runNixos(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	case "sync-workflows":
		if err := runSyncWorkflows(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	default:
		fmt.Fprintf(os.Stderr, "Unknown subcommand: %s\nUsage: ci-build <package|packages|nixos|sync-workflows> [options] [args]\n", subcommand)
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

func pushToCachix(outPaths []string) error {
	if len(outPaths) == 0 {
		return nil
	}
	if _, err := exec.LookPath("cachix"); err != nil {
		fmt.Println("cachix not found in PATH, skipping push.")
		return nil
	}
	fmt.Printf("Pushing %d paths to Cachix...\n", len(outPaths))
	pushArgs := append([]string{"push", "kachick-dotfiles"}, outPaths...)
	pushCmd := exec.Command("cachix", pushArgs...)
	pushCmd.Stdout = os.Stdout
	pushCmd.Stderr = os.Stderr
	return pushCmd.Run()
}

func maybePushToCachix(pname string, isFree bool, outPaths []string) error {
	if !isFree {
		fmt.Printf("Skipping Cachix push for unfree package: %s\n", pname)
		return nil
	}

	if len(outPaths) == 0 {
		return fmt.Errorf("no output paths to push for %s", pname)
	}

	return pushToCachix(outPaths)
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

func getAllPackageLicenses(repoRoot string, arch string) (map[string]bool, error) {
	expr := fmt.Sprintf(`
let
  flake = builtins.getFlake "%s";
  pkgs = flake.inputs.nixpkgs.legacyPackages.%s;
  lib = pkgs.lib;
in
builtins.mapAttrs (name: pkg:
  let
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
) flake.packages.%s
`, repoRoot, arch, arch)

	cmd := exec.Command("nix", "eval", "--impure", "--json", "--expr", expr)
	cmd.Env = append(os.Environ(), "NIXPKGS_ALLOW_UNFREE=1")
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("evaluating package licenses: %w", err)
	}

	var licenses map[string]bool
	if err := json.Unmarshal(out, &licenses); err != nil {
		return nil, fmt.Errorf("unmarshaling license evaluation result: %w", err)
	}
	return licenses, nil
}

func runPackages(args []string) error {
	fs := flag.NewFlagSet("packages", flag.ExitOnError)
	archFlag := fs.String("arch", "", "Target system architecture (defaults to nix builtins.currentSystem)")
	skipTests := fs.Bool("skip-tests", false, "Skip running passthru.tests")

	if err := fs.Parse(args); err != nil {
		return err
	}

	arch := *archFlag
	if arch == "" {
		detectedArch, err := getCurrentNixSystem()
		if err != nil {
			return err
		}
		arch = detectedArch
	}

	repoRootBytes, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		return fmt.Errorf("failed to detect repository root: %w", err)
	}
	repoRoot := strings.TrimSpace(string(repoRootBytes))

	packagesPath := filepath.Join(repoRoot, "packages.toml")
	packagesFile, err := loadPackagesConfig(packagesPath)
	if err != nil {
		return fmt.Errorf("loading packages.toml: %w", err)
	}

	licenses, err := getAllPackageLicenses(repoRoot, arch)
	if err != nil {
		return fmt.Errorf("getting package licenses: %w", err)
	}

	var freeNames []string
	var unfreeNames []string
	for name, cfg := range packagesFile.Packages {
		if !cfg.Build {
			continue
		}
		isFree, ok := licenses[name]
		if !ok {
			var err error
			isFree, err = isPackageFree(name, arch)
			if err != nil {
				return fmt.Errorf("checking license for %s: %w", name, err)
			}
		}
		if isFree {
			freeNames = append(freeNames, name)
		} else {
			unfreeNames = append(unfreeNames, name)
		}
	}
	sort.Strings(freeNames)
	sort.Strings(unfreeNames)

	// 1. Build and push free packages
	if len(freeNames) > 0 {
		var targets []string
		for _, name := range freeNames {
			targets = append(targets, fmt.Sprintf(".#%s", name))
		}
		fmt.Printf("Building %d free packages: %s\n", len(freeNames), strings.Join(freeNames, ", "))
		buildArgs := append([]string{"build"}, targets...)
		buildArgs = append(buildArgs, "--no-link", "--print-out-paths", "--show-trace")

		var outBuf bytes.Buffer
		buildCmd := exec.Command("nix", buildArgs...)
		buildCmd.Stdout = io.MultiWriter(os.Stdout, &outBuf)
		buildCmd.Stderr = os.Stderr
		if err := buildCmd.Run(); err != nil {
			return fmt.Errorf("building free packages: %w", err)
		}

		outPaths := strings.Fields(outBuf.String())
		if err := pushToCachix(outPaths); err != nil {
			return fmt.Errorf("pushing to Cachix: %w", err)
		}
	}

	// 2. Build unfree packages (without Cachix push)
	if len(unfreeNames) > 0 {
		var targets []string
		for _, name := range unfreeNames {
			targets = append(targets, fmt.Sprintf(".#%s", name))
		}
		fmt.Printf("Building %d unfree packages: %s\n", len(unfreeNames), strings.Join(unfreeNames, ", "))
		buildArgs := append([]string{"build", "--impure"}, targets...)
		buildArgs = append(buildArgs, "--no-link", "--show-trace")

		buildCmd := exec.Command("nix", buildArgs...)
		buildCmd.Env = append(os.Environ(), "NIXPKGS_ALLOW_UNFREE=1")
		buildCmd.Stdout = os.Stdout
		buildCmd.Stderr = os.Stderr
		if err := buildCmd.Run(); err != nil {
			return fmt.Errorf("building unfree packages: %w", err)
		}
	}

	// 3. Run passthru.tests
	if *skipTests {
		fmt.Println("Skipping tests as requested.")
		return nil
	}

	allNames := append(freeNames, unfreeNames...)
	sort.Strings(allNames)
	for _, name := range allNames {
		cfg := packagesFile.Packages[name]
		if !cfg.Test {
			continue
		}
		isFree, ok := licenses[name]
		if !ok {
			var err error
			isFree, err = isPackageFree(name, arch)
			if err != nil {
				return fmt.Errorf("checking license for %s: %w", name, err)
			}
		}

		evalTarget := fmt.Sprintf(".#%s.passthru.tests", name)
		evalArgs := []string{"eval", evalTarget}
		if !isFree {
			evalArgs = append(evalArgs, "--impure")
		}
		evalCmd := exec.Command("nix", evalArgs...)
		if !isFree {
			evalCmd.Env = append(os.Environ(), "NIXPKGS_ALLOW_UNFREE=1")
		}
		if err := evalCmd.Run(); err != nil {
			continue // No passthru.tests
		}

		fmt.Printf("Running passthru.tests for %s...\n", name)
		testAttr := fmt.Sprintf("packages.%s.%s.passthru.tests", arch, name)
		testCmd := exec.Command("nix-build", "--attr", testAttr)
		if !isFree {
			testCmd.Env = append(os.Environ(), "NIXPKGS_ALLOW_UNFREE=1")
		}
		testCmd.Stdout = os.Stdout
		testCmd.Stderr = os.Stderr
		if err := testCmd.Run(); err != nil {
			return fmt.Errorf("tests failed for %s: %w", name, err)
		}
	}

	return nil
}

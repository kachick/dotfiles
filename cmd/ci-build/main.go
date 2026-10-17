package main

import (
	"bytes"
	"flag"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Usage: ci-build <package|nixos|push|sync-workflows> [options] [args]")
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
	case "push":
		if err := runPush(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	case "sync-workflows":
		if err := runSyncWorkflows(os.Args[2:]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	default:
		fmt.Fprintf(os.Stderr, "Unknown subcommand: %s\nUsage: ci-build <package|nixos|push|sync-workflows> [options] [args]\n", subcommand)
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
	if err := maybePushToNiks3(pname, isFree, outPaths); err != nil {
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
	var outBuf bytes.Buffer
	buildCmd := exec.Command("nix", "build", buildTarget, "--no-link", "--print-out-paths", "--show-trace")
	buildCmd.Stdout = io.MultiWriter(os.Stdout, &outBuf)
	buildCmd.Stderr = os.Stderr

	if err := buildCmd.Run(); err != nil {
		return err
	}

	outPaths := strings.Fields(outBuf.String())
	if err := maybePushToCachix(host, true, outPaths); err != nil {
		return err
	}
	if err := maybePushToNiks3(host, true, outPaths); err != nil {
		return err
	}

	return nil
}

func isCacheableStorePath(path string) bool {
	// Exclude source tarballs, git clones, vendor directories, and large ISOs
	base := filepath.Base(path)
	if strings.HasSuffix(base, "-source") {
		return false
	}
	if strings.HasSuffix(base, "-vendor") {
		return false
	}
	if strings.HasSuffix(base, ".iso") {
		return false
	}
	if strings.HasSuffix(base, "nixpkgs.tar.gz") {
		return false
	}
	return true
}

func filterCacheablePaths(paths []string) []string {
	seen := make(map[string]bool)
	var filtered []string
	for _, p := range paths {
		trimmed := strings.TrimSpace(p)
		if trimmed == "" {
			continue
		}
		if seen[trimmed] {
			continue
		}
		seen[trimmed] = true
		if isCacheableStorePath(trimmed) {
			filtered = append(filtered, trimmed)
		}
	}
	return filtered
}

func getStorePathClosure(paths []string) ([]string, error) {
	if len(paths) == 0 {
		return nil, nil
	}
	args := append([]string{"path-info", "--recursive"}, paths...)
	cmd := exec.Command("nix", args...)
	out, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to query closure: %w", err)
	}
	allPaths := strings.Fields(string(out))
	return filterCacheablePaths(allPaths), nil
}

func maybePushToNiks3(targetName string, isFree bool, outPaths []string) error {
	if !isFree {
		fmt.Printf("Skipping niks3 push for unfree package: %s\n", targetName)
		return nil
	}

	serverURL := os.Getenv("NIKS3_SERVER_URL")
	if serverURL == "" {
		fmt.Printf("Skipping niks3 push for %s: NIKS3_SERVER_URL not set\n", targetName)
		return nil
	}

	if len(outPaths) == 0 {
		return fmt.Errorf("no output paths to push to niks3 for %s", targetName)
	}

	closurePaths, err := getStorePathClosure(outPaths)
	if err != nil {
		return fmt.Errorf("collecting closure for %s: %w", targetName, err)
	}

	if len(closurePaths) == 0 {
		fmt.Printf("No cacheable paths found for %s, skipping niks3 push\n", targetName)
		return nil
	}

	authToken := os.Getenv("NIKS3_AUTH_TOKEN")
	var tokenArgs []string
	if authToken != "" {
		tokenFile, err := os.CreateTemp("", "niks3-token-*")
		if err != nil {
			return fmt.Errorf("creating temp token file: %w", err)
		}
		defer os.Remove(tokenFile.Name())
		if _, err := tokenFile.WriteString(authToken); err != nil {
			return fmt.Errorf("writing temp token file: %w", err)
		}
		if err := tokenFile.Close(); err != nil {
			return fmt.Errorf("closing temp token file: %w", err)
		}
		tokenArgs = []string{"--auth-token-path", tokenFile.Name()}
	}

	fmt.Printf("Pushing %s to niks3 (%d paths)...\n", targetName, len(closurePaths))

	niks3Bin, err := exec.LookPath("niks3")
	var pushCmd *exec.Cmd
	if err == nil {
		args := []string{"push", "--server-url", serverURL}
		args = append(args, tokenArgs...)
		args = append(args, "--stdin")
		pushCmd = exec.Command(niks3Bin, args...)
	} else {
		args := []string{"run", "nixpkgs#niks3", "--", "push", "--server-url", serverURL}
		args = append(args, tokenArgs...)
		args = append(args, "--stdin")
		pushCmd = exec.Command("nix", args...)
	}

	pushCmd.Stdin = strings.NewReader(strings.Join(closurePaths, "\n") + "\n")
	pushCmd.Stdout = os.Stdout
	pushCmd.Stderr = os.Stderr

	return pushCmd.Run()
}

func runPush(args []string) error {
	fs := flag.NewFlagSet("push", flag.ExitOnError)
	if err := fs.Parse(args); err != nil {
		return err
	}

	if fs.NArg() < 1 {
		return fmt.Errorf("at least one path is required")
	}

	paths := fs.Args()
	return maybePushToNiks3("manual-push", true, paths)
}

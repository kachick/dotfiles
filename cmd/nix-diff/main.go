package main

import (
	"bytes"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"
)

// Target represents a nix flake output to be compared
type Target struct {
	Name      string
	Attribute string
}

// Result holds the diff output for a target
type Result struct {
	Target Target
	Diff   string
	Has    bool
}

func main() {
	baseFlake := flag.String("base", "", "The base flake to compare against (e.g. github:owner/repo/main)")
	currentFlake := flag.String("current", ".", "The current flake to compare (default '.')")
	flag.Parse()

	if *baseFlake == "" {
		fmt.Fprintln(os.Stderr, "Error: -base is required")
		os.Exit(1)
	}

	targets := []Target{
		{Name: "DevShell", Attribute: "devShells.x86_64-linux.default"},
		{Name: "NixOS", Attribute: "nixosConfigurations.algae.config.system.build.toplevel"},
		{Name: "Home Manager", Attribute: `homeConfigurations."github-actions@ubuntu-24.04".activationPackage`},
	}

	// Fetch base flake metadata first to pre-download the source and avoid concurrent fetch issues
	fmt.Fprintf(os.Stderr, "Fetching base flake metadata: %s\n", *baseFlake)
	if err := prefetchFlake(*baseFlake); err != nil {
		fmt.Fprintf(os.Stderr, "Warning: failed to prefetch base flake: %v\n", err)
	}

	results := make([]Result, len(targets))
	var wg sync.WaitGroup

	fmt.Fprintln(os.Stderr, "Starting parallel nix evaluations...")
	start := time.Now()

	for i, t := range targets {
		wg.Go(func() {
			tName := t.Name
			fmt.Fprintf(os.Stderr, "[%s] Evaluating...\n", tName)
			evalStart := time.Now()
			diff, ok := compareTarget(*baseFlake, *currentFlake, t)
			results[i] = Result{Target: t, Diff: diff, Has: ok}
			duration := time.Since(evalStart).Round(time.Second)
			if ok {
				fmt.Fprintf(os.Stderr, "[%s] Done (changes found) in %v.\n", tName, duration)
			} else {
				fmt.Fprintf(os.Stderr, "[%s] Done (no changes) in %v.\n", tName, duration)
			}
		})
	}

	wg.Wait()
	fmt.Fprintf(os.Stderr, "All evaluations finished in %v. Generating report...\n", time.Since(start).Round(time.Second))

	// Print final report to stdout
	fmt.Println("## ❄️ Nix Package Version Changes")
	fmt.Println("<!-- nix-diff-report -->")
	fmt.Println("")

	hasAnyDiff := false
	for _, res := range results {
		if res.Has {
			fmt.Printf("<details open><summary><b>%s</b></summary>\n\n", res.Target.Name)
			fmt.Println("```text")
			fmt.Print(res.Diff)
			fmt.Println("```")
			fmt.Println("</details>\n")
			hasAnyDiff = true
		}
	}

	if !hasAnyDiff {
		fmt.Println("No package version changes detected in monitored targets.")
	}
}

func prefetchFlake(flakePath string) error {
	// Running metadata pre-downloads the flake inputs
	cmd := exec.Command("nix", "flake", "metadata", flakePath)
	return cmd.Run()
}

func compareTarget(base, current string, target Target) (string, bool) {
	oldDrv, err := getDerivation(fmt.Sprintf("%s#%s", base, target.Attribute))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Warning: failed to get old derivation for %s: %v\n", target.Name, err)
		return "", false
	}

	newDrv, err := getDerivation(fmt.Sprintf("%s#%s", current, target.Attribute))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Warning: failed to get new derivation for %s: %v\n", target.Name, err)
		return "", false
	}

	if oldDrv == newDrv {
		return "", false
	}

	// Use dix to diff the derivations
	cmd := exec.Command("nix", "run", "nixpkgs#dix", "--", oldDrv, newDrv)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Warning: dix failed for %s: %v\n", target.Name, err)
		return "", false
	}

	return out.String(), true
}

func getDerivation(flakePath string) (string, error) {
	cmd := exec.Command("nix", "path-info", flakePath, "--derivation")
	var out bytes.Buffer
	cmd.Stdout = &out
	if err := cmd.Run(); err != nil {
		return "", err
	}
	return strings.TrimSpace(out.String()), nil
}

package main

import (
	"bytes"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"strings"
)

// Target represents a nix flake output to be compared
type Target struct {
	Name      string
	Attribute string
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

	fmt.Println("## ❄️ Nix Package Version Changes")
	fmt.Println("")

	hasDiff := false
	for _, target := range targets {
		if diff, ok := compareTarget(*baseFlake, *currentFlake, target); ok {
			fmt.Printf("<details open><summary><b>%s</b></summary>\n\n", target.Name)
			fmt.Println("```text")
			fmt.Print(diff)
			fmt.Println("```")
			fmt.Println("</details>")
			fmt.Println("")
			hasDiff = true
		}
	}

	if !hasDiff {
		fmt.Println("No package version changes detected in monitored targets.")
	}
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
	// Use nix path-info --derivation to get the .drv path
	cmd := exec.Command("nix", "path-info", flakePath, "--derivation")
	var out bytes.Buffer
	cmd.Stdout = &out
	// Suppress warnings in stderr for cleaner output, or log them to stderr
	if err := cmd.Run(); err != nil {
		return "", err
	}
	return strings.TrimSpace(out.String()), nil
}

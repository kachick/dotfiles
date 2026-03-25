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
	targetName := flag.String("target", "", "Optional: specific target name to run (DevShell, NixOS, home-manager-linux, home-manager-darwin)")
	flag.Parse()

	if *baseFlake == "" {
		fmt.Fprintln(os.Stderr, "Error: -base is required")
		os.Exit(1)
	}

	allTargets := []Target{
		{Name: "DevShell", Attribute: "devShells.x86_64-linux.default"},
		{Name: "NixOS", Attribute: "nixosConfigurations.algae.config.system.build.toplevel"},
		{Name: "home-manager-linux", Attribute: `homeConfigurations."github-actions@ubuntu-24.04".activationPackage`},
		{Name: "home-manager-darwin", Attribute: `homeConfigurations."github-actions@macos-15-intel".activationPackage`},
	}

	var targets []Target
	if *targetName != "" {
		for _, t := range allTargets {
			if t.Name == *targetName {
				targets = append(targets, t)
				break
			}
		}
		if len(targets) == 0 {
			fmt.Fprintf(os.Stderr, "Error: target %s not found\n", *targetName)
			os.Exit(1)
		}
	} else {
		targets = allTargets
	}

	// Only print header if running all or as part of a joined report
	if *targetName == "" {
		fmt.Println("## ❄️ Nix Package Version Changes")
		fmt.Println("<!-- nix-diff-report -->")
		fmt.Println("")
	}

	hasDiff := false
	for _, target := range targets {
		diff, err := compareTarget(*baseFlake, *currentFlake, target)
		if err != nil {
			fmt.Printf("<details><summary>⚠️ <b>%s</b> (Failed to evaluate)</summary>\n\n", target.Name)
			fmt.Println("```text")
			fmt.Println(err)
			fmt.Println("```")
			fmt.Println("</details>")
			fmt.Println("")
			hasDiff = true // Treat error as a change to be reported
			continue
		}

		if diff != "" {
			fmt.Printf("<details open><summary><b>%s</b></summary>\n\n", target.Name)
			fmt.Println("```text")
			fmt.Print(diff)
			fmt.Println("```")
			fmt.Println("</details>")
			fmt.Println("")
			hasDiff = true
		}
	}

	if !hasDiff && *targetName == "" {
		fmt.Println("No package version changes detected in monitored targets.")
	}
}

func compareTarget(base, current string, target Target) (string, error) {
	oldDrv, err := getDerivation(fmt.Sprintf("%s#%s", base, target.Attribute))
	if err != nil {
		return "", fmt.Errorf("failed to get old derivation: %w", err)
	}

	newDrv, err := getDerivation(fmt.Sprintf("%s#%s", current, target.Attribute))
	if err != nil {
		return "", fmt.Errorf("failed to get new derivation: %w", err)
	}

	if oldDrv == newDrv {
		return "", nil
	}

	// Use dix to diff the derivations.
	// Dix is guaranteed to be in PATH by the nix packaging (wrapProgram).
	cmd := exec.Command("dix", oldDrv, newDrv)
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("dix failed: %w", err)
	}

	return out.String(), nil
}

func getDerivation(flakePath string) (string, error) {
	cmd := exec.Command("nix", "path-info", flakePath, "--derivation")
	var out, errOut bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = &errOut
	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("%v: %s", err, strings.TrimSpace(errOut.String()))
	}
	return strings.TrimSpace(out.String()), nil
}

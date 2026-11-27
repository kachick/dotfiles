package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"slices"
	"strings"
)

const nixosMarkerPath = "/etc/NIXOS"

func parseApplyFlags(name string, args []string) (dryRun bool, err error) {
	fs := flag.NewFlagSet(name, flag.ContinueOnError)
	fs.SetOutput(io.Discard)
	dryRunFlag := fs.Bool("dry-run", false, "Run without activating changes")
	if err := fs.Parse(args); err != nil {
		return false, fmt.Errorf("usage: dot-task %s [--dry-run]", name)
	}
	if fs.NArg() > 0 {
		return false, fmt.Errorf("usage: dot-task %s [--dry-run]", name)
	}
	return *dryRunFlag, nil
}

func runApply(args []string, e env) error {
	dryRun, err := parseApplyFlags("apply", args)
	if err != nil {
		return err
	}
	if e.fileExists(nixosMarkerPath) {
		return executeNixos(dryRun, e)
	}
	return executeHomeManager(dryRun, e)
}

func runNixos(args []string, e env) error {
	dryRun, err := parseApplyFlags("nixos", args)
	if err != nil {
		return err
	}
	return executeNixos(dryRun, e)
}

func executeNixos(dryRun bool, e env) error {
	available, err := listFlakeAttrs("nixosConfigurations", e)
	if err != nil {
		return err
	}

	host, _ := e.hostname()
	target, err := resolveFlakeTarget("nixosConfigurations", host, available, "nixos> ", e)
	if err != nil {
		if errors.Is(err, errSelectionCanceled) {
			return nil
		}
		return err
	}

	if dryRun {
		// Prefer "build" rather than "test" and "dry-reactivate" for speed and not requiring root permissions.
		return e.runCmd("nixos-rebuild", "build", "--flake", ".#"+target, "--show-trace")
	}
	return e.runCmd("sudo", "nixos-rebuild", "switch", "--flake", ".#"+target, "--show-trace")
}

func runCheckNixos(args []string, e env) error {
	if len(args) > 0 {
		return errors.New("usage: dot-task check-nixos")
	}

	hosts, err := listFlakeAttrs("nixosConfigurations", e)
	if err != nil {
		return err
	}
	if len(hosts) == 0 {
		return errors.New("no entries found in flake nixosConfigurations")
	}

	cmdArgs := make([]string, 0, len(hosts)+2)
	cmdArgs = append(cmdArgs, "build", "--dry-run")
	for _, host := range hosts {
		cmdArgs = append(cmdArgs, ".#nixosConfigurations."+host+".config.system.build.toplevel")
	}
	return e.runCmd("nix", cmdArgs...)
}

func runHomeManager(args []string, e env) error {
	dryRun, err := parseApplyFlags("home-manager", args)
	if err != nil {
		return err
	}
	return executeHomeManager(dryRun, e)
}

func executeHomeManager(dryRun bool, e env) error {
	available, err := listFlakeAttrs("homeConfigurations", e)
	if err != nil {
		return err
	}

	user := e.getenv("USER")
	host, _ := e.hostname()
	candidate := ""
	if user != "" && host != "" {
		candidate = user + "@" + host
	}

	target, err := resolveFlakeTarget("homeConfigurations", candidate, available, "home-manager> ", e)
	if err != nil {
		if errors.Is(err, errSelectionCanceled) {
			return nil
		}
		return err
	}

	if dryRun {
		// -n = dry-run
		return e.runCmd("nix", "run", ".#home-manager", "--", "switch", "-n", "-b", "backup", "--show-trace", "--flake", ".#"+target)
	}
	return e.runCmd("nix", "run", ".#home-manager", "--", "switch", "-b", "backup", "--show-trace", "--flake", ".#"+target)
}

func listFlakeAttrs(attr string, e env) ([]string, error) {
	out, err := e.cmdOutput("nix", "eval", "--json", ".#"+attr, "--apply", "builtins.attrNames")
	if err != nil {
		return nil, fmt.Errorf("listing %s from flake: %w", attr, err)
	}

	var names []string
	if err := json.Unmarshal(out, &names); err != nil {
		return nil, fmt.Errorf("parsing %s names: %w", attr, err)
	}
	slices.Sort(names)
	return names, nil
}

func resolveFlakeTarget(attr, candidate string, available []string, prompt string, e env) (string, error) {
	if len(available) == 0 {
		return "", fmt.Errorf("no entries found in flake %s", attr)
	}

	if candidate != "" && slices.Contains(available, candidate) {
		return candidate, nil
	}

	if !e.isTerminal() {
		return "", fmt.Errorf("could not auto-detect %s target (candidate %q) in non-interactive shell; available: %s", attr, candidate, strings.Join(available, ", "))
	}

	header := fmt.Sprintf("Select %s target:", attr)
	if candidate != "" {
		header = fmt.Sprintf("%q not found in %s. Select target:", candidate, attr)
	}
	return e.selectItem(available, prompt, header)
}

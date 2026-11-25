package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"slices"
	"strings"
)

const nixosMarkerPath = "/etc/NIXOS"

func runApply(args []string, e env) error {
	if len(args) > 0 {
		return errors.New("usage: task apply")
	}
	if e.fileExists(nixosMarkerPath) {
		return runNixos(nil, e)
	}
	return runHomeManager(nil, e)
}

func runNixos(args []string, e env) error {
	if len(args) > 0 {
		return errors.New("usage: task nixos")
	}

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

	return e.runCmd("sudo", "nixos-rebuild", "switch", "--flake", ".#"+target, "--show-trace")
}

func runHomeManager(args []string, e env) error {
	if len(args) > 0 {
		return errors.New("usage: task home-manager")
	}

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

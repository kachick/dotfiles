package main

import (
	"errors"
	"fmt"
)

const nixosMarkerPath = "/etc/NIXOS"

func runApply(args []string, e env) error {
	if e.fileExists(nixosMarkerPath) {
		return runNixos(args, e)
	}
	return runHomeManager(args, e)
}

func runNixos(args []string, e env) error {
	if len(args) > 1 {
		return errors.New("usage: task nixos [-- <host>]")
	}

	var host string
	if len(args) == 1 {
		host = args[0]
	} else {
		var err error
		host, err = e.hostname()
		if err != nil {
			return fmt.Errorf("getting hostname: %w", err)
		}
	}

	return e.runCmd("sudo", "nixos-rebuild", "switch", "--flake", ".#"+host, "--show-trace")
}

func runHomeManager(args []string, e env) error {
	// Require an explicit host slug instead of hostname because multiple machines may share one config (e.g. wsl-ubuntu).
	if len(args) != 1 {
		return errors.New("usage: task home-manager -- <host-slug>")
	}

	user := e.getenv("USER")
	if user == "" {
		return errors.New("USER environment variable is not set")
	}

	target := fmt.Sprintf(".#%s@%s", user, args[0])
	return e.runCmd("nix", "run", ".#home-manager", "--", "switch", "-b", "backup", "--show-trace", "--flake", target)
}

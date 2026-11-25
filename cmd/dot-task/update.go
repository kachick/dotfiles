package main

import "errors"

func runUpdate(args []string, e env) error {
	if len(args) > 0 {
		return errors.New("usage: task update")
	}

	if err := e.runCmd("nix", "flake", "update"); err != nil {
		return err
	}
	if err := e.runCmd("nix", "run", ".#dedup-flake-inputs"); err != nil {
		return err
	}

	clean, err := e.cmdExitOK("git", "diff", "--exit-code", "flake.nix", "flake.lock")
	if err != nil {
		return err
	}
	if !clean {
		if err := e.runCmd("git", "commit", "--no-gpg-sign", "-m", "flake.lock: Update", "flake.nix", "flake.lock"); err != nil {
			return err
		}
	}

	return e.runCmd("nix", "run", ".#bump_gomod", "--", ".", "cmd/winit-reg")
}

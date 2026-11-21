package main

import (
	"encoding/json"
	"os/exec"
	"strings"
	"testing"
)

// TestUpdateScripts_FlakeArg verifies that all packages marked with `update = true`
// in pkgs/list.toml that use nix-update-script include `--flake` in extraArgs.
// nix-update does not automatically propagate `--flake` to child update scripts:
// https://github.com/Mic92/nix-update/pull/330
func TestUpdateScripts_FlakeArg(t *testing.T) {
	if _, err := exec.LookPath("nix"); err != nil {
		t.Skip("skipping test: nix is not installed in PATH")
	}

	repoRootBytes, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		t.Fatalf("failed to detect repository root: %v", err)
	}
	repoRoot := strings.TrimSpace(string(repoRootBytes))

	expr := `
let
  flake = builtins.getFlake (toString ./.);
  system = builtins.currentSystem;
  pkgs = flake.packages.${system};
  config = builtins.fromTOML (builtins.readFile ./pkgs/list.toml);
  lib = flake.inputs.nixpkgs.lib;

  updatePkgs = lib.filterAttrs (_: cfg: cfg.update or false) config.packages;

  checkPkg = name: _:
    let
      pkg = pkgs.${name} or null;
      script = if pkg != null then (pkg.passthru.updateScript or pkg.updateScript or null) else null;
    in
    if builtins.isList script && builtins.any (arg: lib.hasSuffix "/bin/nix-update" (toString arg)) script then
      if builtins.elem "--flake" script then
        null
      else
        "${name}: updateScript uses nix-update-script but is missing \"--flake\" in extraArgs"
    else
      null;

  errors = lib.filter (e: e != null) (lib.mapAttrsToList checkPkg updatePkgs);
in
errors
`
	cmd := exec.Command("nix", "eval", "--impure", "--json", "--expr", expr)
	cmd.Dir = repoRoot
	out, err := cmd.Output()
	if err != nil {
		if exitErr, ok := err.(*exec.ExitError); ok {
			t.Fatalf("evaluating updateScripts via nix: %s: %v", string(exitErr.Stderr), err)
		}
		t.Fatalf("evaluating updateScripts via nix: %v", err)
	}

	var errList []string
	if err := json.Unmarshal(out, &errList); err != nil {
		t.Fatalf("unmarshaling updateScripts eval result: %v", err)
	}

	if len(errList) > 0 {
		t.Errorf("updateScript validation failed:\n  %s", strings.Join(errList, "\n  "))
	}
}

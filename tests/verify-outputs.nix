let
  flake = builtins.getFlake (toString ./.);
  lib = flake.inputs.nixpkgs.lib;

  # Helper to check if a specific patch exists in a package
  hasMozcPatch = pkg: builtins.any (p: p.name == "GH-1277.patch") (pkg.patches or [ ]);

  # Helper to check if a package set has the project-specific 'unstable' attribute
  hasUnstable = pkgs: pkgs ? unstable;
in
{
  # 1. Verify top-level flake outputs
  flakeOverlaysHasDefault = flake.outputs.overlays ? default;

  # 2. Verify NixOS configurations (Checking a specific host)
  nixosMossHasOverlays =
    let
      # Evaluate the configuration's nixpkgs overlays
      pkgs = flake.nixosConfigurations.moss.pkgs;
    in
    {
      inherit (pkgs.lib) version;
      hasUnstable = hasUnstable pkgs;
      mozcIsPatched = hasMozcPatch pkgs.mozc;
    };

  # 3. Verify Home Manager configurations
  homeWslHasOverlays =
    let
      pkgs = flake.homeConfigurations."kachick@wsl-ubuntu".pkgs;
    in
    {
      inherit (pkgs.lib) version;
      hasUnstable = hasUnstable pkgs;
      mozcIsPatched = hasMozcPatch pkgs.mozc;
    };
}

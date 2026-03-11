{ config, lib, ... }:
{
  options.nixpkgs.allowedUnfreePackageNames = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      List of unfree package names (strings) to allow.

      NOTE: We use strings instead of package objects (e.g., [ pkgs.vscode ]) because
      referencing the package object triggers a license check during evaluation
      BEFORE the allowUnfreePredicate is applied, leading to an evaluation error.
    '';
  };

  config.nixpkgs.config.allowUnfreePredicate =
    pkg: builtins.elem (lib.getName pkg) config.nixpkgs.allowedUnfreePackageNames;
}

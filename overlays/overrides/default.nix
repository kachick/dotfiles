{ home-manager-linux, home-manager-darwin }:
final: prev:
let
  inherit (prev) lib;
  callPackage = lib.callPackageWith (
    final // { inherit prev home-manager-linux home-manager-darwin; }
  );

  # Read all .nix files in this directory except default.nix
  files = builtins.readDir ./.;
  nixFiles = lib.filterAttrs (
    name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
  ) files;
in
lib.mapAttrs' (
  name: _type:
  let
    pname = lib.removeSuffix ".nix" name;
  in
  lib.nameValuePair pname (callPackage (./. + "/${name}") { })
) nixFiles

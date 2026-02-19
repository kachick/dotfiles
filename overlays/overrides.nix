{ home-manager-linux, home-manager-darwin }:
final: prev:
let
  inherit (prev) lib;
  callPackage = lib.callPackageWith (
    final // { inherit prev home-manager-linux home-manager-darwin; }
  );

  files = builtins.readDir ./overrides;
  nixFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) files;
in
lib.mapAttrs' (
  name: _type:
  let
    pname = lib.removeSuffix ".nix" name;
  in
  lib.nameValuePair pname (callPackage (./overrides + "/${name}") { })
) nixFiles

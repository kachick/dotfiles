{ ... }:
final: prev:
let
  inherit (prev) lib;
  callPackage = lib.callPackageWith (final // { inherit prev; });
in
# Read all .nix files in this directory except default.nix
lib.pipe ./. [
  builtins.readDir
  (lib.filterAttrs (
    name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
  ))
  (lib.mapAttrs' (
    name: _type:
    let
      pname = lib.removeSuffix ".nix" name;
    in
    lib.nameValuePair pname (callPackage (./. + "/${name}") { })
  ))
]

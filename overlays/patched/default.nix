{ kanata-tray }:
final: _prev:
let
  inherit (_prev) lib;
  callPackage = lib.callPackageWith (final // { inherit kanata-tray; });

  # Read all .nix files in this directory except default.nix
  files = builtins.readDir ./.;
  nixFiles = lib.filterAttrs (
    name: type: type == "regular" && lib.hasSuffix ".nix" name && name != "default.nix"
  ) files;
in
{
  patched = lib.mapAttrs' (
    name: _type:
    let
      pname = lib.removeSuffix ".nix" name;
    in
    lib.nameValuePair pname (callPackage (./. + "/${name}") { })
  ) nixFiles;
}

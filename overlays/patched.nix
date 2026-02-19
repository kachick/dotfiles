{ kanata-tray }:
final: _prev:
let
  inherit (_prev) lib;
  callPackage = lib.callPackageWith (final // { inherit kanata-tray; });

  files = builtins.readDir ./patched;
  nixFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) files;
in
{
  patched = lib.mapAttrs' (
    name: _type:
    let
      pname = lib.removeSuffix ".nix" name;
    in
    lib.nameValuePair pname (callPackage (./patched + "/${name}") { })
  ) nixFiles;
}

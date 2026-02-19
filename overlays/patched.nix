{ kanata-tray }:
final: _prev:
let
  inherit (final) lib;
  callPackage = lib.callPackageWith (final // { inherit kanata-tray; });
in
{
  patched = {
    kanata-tray = callPackage ./patched/kanata-tray/package.nix { };
    gemini-cli-bin = callPackage ./patched/gemini-cli-bin/package.nix { };
    rclone = callPackage ./patched/rclone/package.nix { };
  };
}

{ home-manager-linux, home-manager-darwin }:
final: prev:
let
  inherit (final) lib;
  # callPackage に渡す引数を明示的に管理する
  callPackage = lib.callPackageWith (
    final
    // {
      inherit
        prev
        home-manager-linux
        home-manager-darwin
        ;
    }
  );
in
{
  mozc = callPackage ./overrides/mozc/package.nix { };
  inetutils = callPackage ./overrides/inetutils/package.nix { };
  home-manager = callPackage ./overrides/home-manager/package.nix { };
}

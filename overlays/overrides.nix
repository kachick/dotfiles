{ home-manager-linux, home-manager-darwin }:
final: prev:
final.lib.packagesFromDirectoryRecursive {
  callPackage = final.lib.callPackageWith (
    final // { inherit prev home-manager-linux home-manager-darwin; }
  );
  directory = ./overrides;
}

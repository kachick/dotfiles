{ home-manager-linux, home-manager-darwin }:
final: _prev: {
  local = final.lib.packagesFromDirectoryRecursive {
    inherit (final) callPackage;
    directory = ../pkgs/local;
  };

  # Override or pass home-manager specifically to archive-home-files if needed,
  # but since we want to pass it through callPackage, we add it to the scope.
  # Using an extension of the final scope so callPackage finds 'home-manager'.
  home-manager =
    let
      hm =
        if final.stdenv.hostPlatform.isDarwin then
          home-manager-darwin.packages.${final.stdenv.hostPlatform.system}.home-manager
        else
          home-manager-linux.packages.${final.stdenv.hostPlatform.system}.home-manager;
    in
    hm;
}

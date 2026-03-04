final: _prev: {
  local = final.lib.packagesFromDirectoryRecursive {
    inherit (final) callPackage;
    directory = ../pkgs/local;
  };
}

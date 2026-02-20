final: _prev: {
  my = final.lib.packagesFromDirectoryRecursive {
    inherit (final) callPackage;
    directory = ../pkgs;
  };
}

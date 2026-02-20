final: _prev: {
  my =
    final.lib.packagesFromDirectoryRecursive {
      inherit (final) callPackage;
      directory = ../pkgs;
    }
    // {
      constants = {
        nix-config = import ../config/nix/constants.nix;
      };
    };
}

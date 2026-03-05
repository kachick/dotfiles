final: _prev: {
  local =
    final.lib.packagesFromDirectoryRecursive {
      inherit (final) callPackage;
      directory = ../pkgs/local;
    }
    // {
      constants = {
        nix-config = import ../config/nix/constants.nix;
      };
    };
}

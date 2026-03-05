{ self }:
final: _prev: {
  local =
    final.lib.packagesFromDirectoryRecursive {
      callPackage = final.lib.callPackageWith (final // { outputs = self; });
      directory = ../pkgs/local;
    }
    // {
      outputs = self;
    };
}

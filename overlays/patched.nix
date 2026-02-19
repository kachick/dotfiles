{ kanata-tray }:
final: _prev: {
  patched = final.lib.packagesFromDirectoryRecursive {
    callPackage = final.lib.callPackageWith (final // { inherit kanata-tray; });
    directory = ./patched;
  };
}

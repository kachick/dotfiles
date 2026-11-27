final: _prev: {
  local =
    let
      byNameDir = ../pkgs/by-name;
    in
    final.lib.pipe byNameDir [
      builtins.readDir
      builtins.attrNames
      (builtins.concatMap (
        prefix:
        let
          prefixDir = byNameDir + "/${prefix}";
        in
        final.lib.pipe prefixDir [
          builtins.readDir
          builtins.attrNames
          (map (name: {
            inherit name;
            value = final.callPackage (prefixDir + "/${name}/package.nix") { };
          }))
        ]
      ))
      builtins.listToAttrs
    ];
}

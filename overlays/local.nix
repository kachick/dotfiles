final: _prev: {
  local =
    let
      byNameDir = ../pkgs/by-name;
      prefixes = builtins.attrNames (builtins.readDir byNameDir);
      packageEntries = final.lib.concatLists (
        map (
          prefix:
          let
            prefixDir = byNameDir + "/${prefix}";
          in
          map (name: {
            inherit name;
            path = prefixDir + "/${name}/package.nix";
          }) (builtins.attrNames (builtins.readDir prefixDir))
        ) prefixes
      );
    in
    builtins.listToAttrs (
      map (
        { name, path }:
        {
          inherit name;
          value = final.callPackage path { };
        }
      ) packageEntries
    );
}

{ overlays }:
let
  inherit (builtins)
    readDir
    attrNames
    filter
    listToAttrs
    replaceStrings
    match
    ;

  # Directory to scan (home-manager root)
  baseDir = ../.;
  dirContents = readDir baseDir;

  # Filter for .nix files, excluding entry points and library
  moduleFiles = filter (
    name:
    let
      type = dirContents.${name};
    in
    (type == "regular" && match ".*\\.nix" name != null && name != "default.nix" && name != "lib.nix")
  ) (attrNames dirContents);

  # Map filenames to attribute set
  autoModules = listToAttrs (
    map (name: {
      name = replaceStrings [ ".nix" ] [ "" ] name;
      value = baseDir + "/${name}";
    }) moduleFiles
  );
in
autoModules
// {
  inherit overlays;
}

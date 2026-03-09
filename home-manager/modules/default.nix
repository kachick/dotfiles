{ overlays }:
let
  inherit (builtins) listToAttrs;

  # Modules located in the parent directory
  rootModules = [
    "common"
    "linux"
    "genericLinux"
    "ephemeral"
    "darwin"
    "systemd"
    "wsl"
    "lima-guest"
    "lima-host"
  ];

  # Modules located in the current directory (wrappers)
  localModules = [
    "desktop"
    "kachick"
  ];

  rootAttrs = listToAttrs (
    map (name: {
      inherit name;
      value = ../. + "/${name}.nix";
    }) rootModules
  );

  localAttrs = listToAttrs (
    map (name: {
      inherit name;
      value = ./. + "/${name}.nix";
    }) localModules
  );
in
rootAttrs
// localAttrs
// {
  overlays = {
    nixpkgs.overlays = [ overlays.default ];
  };
}

{
  pkgs,
  lib,
  ...
}:
let
  # Directly import the Nix module to extract binary cache settings.
  # This works because nix.nix is a pure attribute set.
  nixConfig = (import ../../../nixos/nix.nix).nix.settings;
  conf = ''
    extra-substituters = ${lib.concatStringsSep " " nixConfig.extra-trusted-substituters}
    extra-trusted-public-keys = ${lib.concatStringsSep " " nixConfig.extra-trusted-public-keys}
  '';
in
pkgs.writeShellScriptBin "gen-nix-cache-conf" ''
  echo "${conf}"
''

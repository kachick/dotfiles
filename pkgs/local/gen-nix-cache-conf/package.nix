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
    # Use 'extra-trusted-substituters' for system-wide configuration.
    # This marks these URLs as trusted but does not enable them globally.
    # Projects can then opt-in to use these by specifying 'extra-substituters' in their flake.nix nixConfig.
    extra-trusted-substituters = ${lib.concatStringsSep " " nixConfig.extra-trusted-substituters}
    extra-trusted-public-keys = ${lib.concatStringsSep " " nixConfig.extra-trusted-public-keys}
  '';
in
pkgs.writeShellScriptBin "gen-nix-cache-conf" ''
  echo "${conf}"
''

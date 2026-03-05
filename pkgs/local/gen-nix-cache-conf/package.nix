{
  pkgs,
  lib,
  outputs,
  ...
}:
let
  # Extract the configuration from a representative NixOS host.
  # This avoids the need for a separate binary-caches.nix file.
  nixConfig = outputs.nixosConfigurations.wsl.config.nix.settings;
  conf = ''
    extra-substituters = ${lib.concatStringsSep " " nixConfig.extra-trusted-substituters}
    extra-trusted-public-keys = ${lib.concatStringsSep " " nixConfig.extra-trusted-public-keys}
  '';
in
pkgs.writeShellScriptBin "gen-nix-cache-conf" ''
  echo "${conf}"
''

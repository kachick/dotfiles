{
  pkgs,
  lib,
  ...
}:
let
  binary-caches = import ../../../config/nix/binary-caches.nix;
  conf = ''
    extra-substituters = ${lib.concatStringsSep " " binary-caches.extra-trusted-substituters}
    extra-trusted-public-keys = ${lib.concatStringsSep " " binary-caches.extra-trusted-public-keys}
  '';
in
pkgs.writeShellScriptBin "gen-nix-cache-conf" ''
  echo "${conf}"
''

{
  pkgs,
  lib,
  ...
}:
let
  binary-caches = import ../../../config/nix/binary-caches.nix;
  conf = ''
    extra-substituters = ${lib.concatStringsSep " " binary-caches.substituters}
    extra-trusted-public-keys = ${lib.concatStringsSep " " binary-caches.trusted-public-keys}
  '';
in
pkgs.writeShellScriptBin "gen-nix-cache-conf" ''
  echo "${conf}"
''

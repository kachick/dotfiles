args@{
  pkgs,
  lib,
  ...
}:

let
  outputs = args.outputs or null;
in
lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && pkgs.stdenv.hostPlatform.isx86_64 && outputs != null)
  {
    home.packages = [
      outputs.packages.${pkgs.stdenv.hostPlatform.system}.microvm-sandbox
    ];
  }

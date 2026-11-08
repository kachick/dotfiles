args@{
  pkgs,
  lib,
  ...
}:

let
  outputs = args.outputs or null;
in
lib.mkIf (pkgs.stdenv.isLinux && pkgs.stdenv.isx86_64 && outputs != null) {
  home.packages = [
    outputs.packages.${pkgs.system}.microvm-sandbox
  ];
}

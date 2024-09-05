{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "zj";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    coreutils
    zellij
  ];
  runtimeEnv = {
    ZELLIJ_LAYOUT_BPS_PATH = "${../../config/zellij/layouts/regular.kdl}";
  };
}

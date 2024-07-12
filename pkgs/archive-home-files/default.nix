{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "archive-home-files";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    gnutar
    ripgrep
    coreutils
  ];
  meta = {
    description = "Backup dotfiles they are generated with home-manager. See #243";
  };
}

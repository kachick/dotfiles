{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "p";
  runtimeInputs = with pkgs; [
    nix
    zsh
  ];
  text = ''
    # Needless to trim the default command, nix-shell only runs last command if given multiple.
    nix-shell --command 'zsh' --packages "$@"
  '';
}

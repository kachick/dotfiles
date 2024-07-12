{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "p";
  runtimeInputs = with pkgs; [ nix ];
  text = ''
    # Needless to trim the default command, nix-shell only runs last command if given multiple.
    nix-shell --command "$SHELL" --packages "$@"
  '';
}

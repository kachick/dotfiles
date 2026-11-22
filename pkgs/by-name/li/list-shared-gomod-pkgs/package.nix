{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "list-shared-gomod-pkgs";
  runtimeInputs = [ pkgs.nix ];
  text = ''
    exec ${pkgs.lib.getExe pkgs.bash} ${./list-shared-gomod-pkgs.bash} ${pkgs.lib.escapeShellArg pkgs.stdenv.hostPlatform.system} "$@"
  '';
  meta = {
    description = "List local packages sharing the root go.mod";
  };
}

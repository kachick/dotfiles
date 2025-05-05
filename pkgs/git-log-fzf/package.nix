{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "git-log-fzf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs =
    with pkgs;
    [
      unstable.fzf
      coreutils
      git
      gh
      colorized-logs
      bat
      riffdiff
      my.git-log-simple
    ]
    ++ (lib.optionals stdenv.isLinux [
      wslu # WSL helpers like `wslview`. It is used in open browser features in gh command
    ]);
  meta = {
    description = "Faster git log searcher for large repositories(e.g NixOS/nixpkgs)";
  };
}

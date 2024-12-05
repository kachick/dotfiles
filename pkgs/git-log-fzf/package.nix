{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "git-log-fzf";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs =
    with pkgs;
    [
      fzf
      coreutils
      git
      gh
      colorized-logs
      bat
      riffdiff
      (import ../git-log-simple/package.nix { inherit pkgs; })
    ]
    ++ (lib.optionals stdenv.isLinux [
      wslu # WSL helpers like `wslview`. It is used in open browser features in gh command
    ]);
}

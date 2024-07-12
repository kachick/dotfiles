{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "prs";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs =
    with pkgs;
    [
      coreutils
      fzf
      gh
      (import ../wait-and-squashmerge { inherit pkgs; })
    ]
    ++ (lib.optionals stdenv.isLinux [
      wslu # WSL helpers like `wslview`. It is used in open browser features in gh command
    ]);
}

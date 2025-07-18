{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "gh-prs";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs =
    with pkgs;
    [
      coreutils
      fzf
      gh
      my.wait-and-squashmerge
    ]
    ++ (lib.optionals stdenv.isLinux [
      wslu # WSL helpers like `wslview`. It is used in open browser features in gh command
    ]);
  derivationArgs = {
    # Required in https://github.com/nix-community/home-manager/blob/346973b338365240090eded0de62f7edce4ce3d1/modules/programs/gh.nix#L160
    pname = name;
  };
  meta = {
    description = "A gh extension to list and operate PRs";
  };
}

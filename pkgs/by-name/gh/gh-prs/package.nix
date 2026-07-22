{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "gh-prs";
  text = builtins.readFile ./gh-prs.bash;
  runtimeInputs = with pkgs; [
    coreutils
    fzf
    gh
    local.wait-and-squashmerge
  ];
  derivationArgs = {
    # Required in https://github.com/nix-community/home-manager/blob/346973b338365240090eded0de62f7edce4ce3d1/modules/programs/gh.nix#L160
    pname = "gh-prs";
  };
  meta = {
    description = "A gh extension to list and operate PRs";
  };
}

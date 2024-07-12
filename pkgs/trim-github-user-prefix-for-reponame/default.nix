{ pkgs, ... }:
pkgs.buildGo122Module rec {
  pname = "trim-github-user-prefix-for-reponame";
  version = "0.0.1";
  default = pname;
  vendorHash = null;
  src = ./.;

  meta = {
    description = "kachick/dotfiles => dotfiles, dotfiles => dotfiles";
    mainProgram = pname;
  };
}

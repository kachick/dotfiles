{ lib, pkgs, ... }:
pkgs.buildGo122Module rec {
  pname = "walk";
  version = "0.0.1";
  default = pname;
  vendorHash = null;
  src = ./.;

  runtimeInputs = with pkgs; [
    fzf
    fd
    bat
  ];

  meta = {
    description = "find file with fuzzy finder, and open it in TUI editor";
    mainProgram = pname;
  };
}

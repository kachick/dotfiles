{ lib, pkgs, ... }:
pkgs.buildGo122Module rec {
  pname = "walk";
  version = "0.0.1";
  default = pname;
  vendorHash = "sha256-Y7DufJ0l+IZ/l2/LPmFRJevc+MCPqGxnESn7RWmSatg=";
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

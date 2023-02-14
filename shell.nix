{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/8eabb500ebf5dcb9a40024c1150ef348cefa8320.tar.gz") { } }:

pkgs.mkShell {
  buildInputs = [
    pkgs.dprint
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.nil
    pkgs.nixpkgs-fmt
    pkgs.pre-commit
    pkgs.go_1_19 # https://github.com/zricethezav/gitleaks/blob/088f8b80742d5fc22f527a53f49cdeec42ece863/go.mod#L3
  ];
}

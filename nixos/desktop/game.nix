# This file defines GUI VM management on NixOS desktop. See also lima related files in home-manager

{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Board Game

    # Use latest to apply https://github.com/NixOS/nixpkgs/pull/418154
    unstable.vassal

    my.ludii

    # Shogi

    ## Install yaneuraou for each host with the optimized label if required
    ## If installing at here, it should be "SSE2"

    ## shogihome does not provide configuration schema and ENV, so manually setup the foollowing NNUE evaluation files for the engine
    # Related issue: https://github.com/sunfish-shogi/shogihome/issues/1017
    (unstable.shogihome.override {
      commandLineArgs = [
        "--wayland-text-input-version=3"
      ];
    })

    my.tanuki-hao # NNUE evaluation file. It put under /run/current-system/sw/share/eval
  ];
}

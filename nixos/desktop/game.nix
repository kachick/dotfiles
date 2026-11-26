{ lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Shogi

    ## Install yaneuraou for each host with the optimized label if required
    ## If installing at here, it should be "SSE2"

    ## shogihome does not provide configuration schema and ENV except CLI options, so manually setup the foollowing NNUE evaluation files for the engine
    # Related issue: https://github.com/sunfish-shogi/shogihome/issues/1017
    shogihome

    local.tanuki-hao # NNUE evaluation file. It put under /run/current-system/sw/share/tanuki-hao/eval
  ];

  programs.gamescope = {
    enable = true;
    # Cap resolution and unfocused FPS to keep GNOME responsive on iGPU hosts.
    args = lib.mkDefault [
      "-w"
      "1920"
      "-h"
      "1080"
      "-r"
      "60"
      "-o"
      "15"
    ];
  };
}

{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Board Game

    # Use latest to apply https://github.com/NixOS/nixpkgs/pull/418154
    unstable.vassal

    my.ludii-bin

    # Shogi

    ## Install yaneuraou for each host with the optimized label if required
    ## If installing at here, it should be "SSE2"

    ## shogihome does not provide configuration schema and ENV except CLI options, so manually setup the foollowing NNUE evaluation files for the engine
    # Related issue: https://github.com/sunfish-shogi/shogihome/issues/1017
    unstable.shogihome

    my.tanuki-hao # NNUE evaluation file. It put under /run/current-system/sw/share/tanuki-hao/eval
  ];
}

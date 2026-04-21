{
  pkgs,
  lib,
  config,
  ...
}:
{
  environment.systemPackages = lib.optionals (!config.profiles.recovery) (
    with pkgs;
    [
      # Board Game

      # Use latest to avoid update notifier (Might be better disabling it in nixpkgs)
      unstable.vassal

      # Shogi

      ## Install yaneuraou for each host with the optimized label if required
      ## If installing at here, it should be "SSE2"

      ## shogihome does not provide configuration schema and ENV except CLI options, so manually setup the foollowing NNUE evaluation files for the engine
      # Related issue: https://github.com/sunfish-shogi/shogihome/issues/1017
      unstable.shogihome

      local.tanuki-hao # NNUE evaluation file. It put under /run/current-system/sw/share/tanuki-hao/eval
    ]
  );
}

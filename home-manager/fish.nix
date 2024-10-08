{ pkgs, ... }:

{
  services.gpg-agent.enableFishIntegration = true;
  programs.starship.enableFishIntegration = true;
  # Settled by default and readonly https://github.com/nix-community/home-manager/blob/8c731978f0916b9a904d67a0e53744ceff47882c/modules/programs/direnv.nix#L65-L68
  # programs.direnv.enableFishIntegration = true;
  programs.zoxide.enableFishIntegration = true;
  programs.fzf.enableFishIntegration = true;
  # Avoid nested zellij in host and remote login as container
  programs.zellij.enableFishIntegration = false;

  xdg.configFile."fish/fish_variables".source = ../config/fish/fish_variables;
  xdg.configFile."fish/functions/fish_prompt.fish".source = ../config/fish/functions/fish_prompt.fish;

  # https://fishshell.com/docs/current/completions.html
  # home-manager doesn't accept the special attrset: https://github.com/nix-community/home-manager/blob/1d085ea4444d26aa52297758b333b449b2aa6fca/modules/programs/fish.nix
  # If added here, check the result of `bench_shells`: https://github.com/kachick/dotfiles/pull/423/files#r1503804605
  xdg.dataFile."fish/vendor_completions.d/podman.fish".source = "${pkgs.podman}/share/fish/vendor_completions.d/podman.fish";
  xdg.dataFile."fish/vendor_completions.d/dprint.fish".source = ../dependencies/dprint/completions.fish;

  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/fish.nix
  programs.fish = {
    enable = true;

    shellInit = ''
      switch (uname -s)
      case Linux
          # Keep this comment
      case Darwin
        # nix
        # https://github.com/NixOS/nix/issues/2280
        if test -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
          fenv source '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        end
      case FreeBSD NetBSD DragonFly
          # Keep this comment
      case '*'
          # Keep this comment
      end

      # nix
      if test -e "$HOME/.nix-profile/etc/profile.d/nix.sh"
          fenv source "$HOME/.nix-profile/etc/profile.d/nix.sh"
      end
    '';

    interactiveShellInit = ''
      # I define another la as a homemade scripts
      # See https://stackoverflow.com/a/36700734/1212807 for using `--erase`
      functions --erase la

      set -g fish_greeting
    '';

    plugins = [
      {
        name = "foreign-env";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "plugin-foreign-env";
          rev = "3ee95536106c11073d6ff466c1681cde31001383";
          sha256 = "sha256-vyW/X2lLjsieMpP9Wi2bZPjReaZBkqUbkh15zOi8T4Y=";
        };
      }
    ];
  };
}

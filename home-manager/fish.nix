{ pkgs, ... }:

{
  programs.starship.enableFishIntegration = true;
  # Settled by default and readonly https://github.com/nix-community/home-manager/blob/8c731978f0916b9a904d67a0e53744ceff47882c/modules/programs/direnv.nix#L65-L68
  # programs.direnv.enableFishIntegration = true;
  programs.zoxide.enableFishIntegration = true;
  programs.fzf.enableFishIntegration = true;
  programs.rtx.enableFishIntegration = true;

  xdg.configFile."fish/fish_variables".source = ../home/.config/fish/fish_variables;
  xdg.configFile."fish/functions/fish_prompt.fish".source = ../home/.config/fish/functions/fish_prompt.fish;

  programs.fish = {
    enable = true;

    shellInit =
      ''
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

      source "${../dependencies/dprint/completions.fish}"
    '';

    plugins = [{
      name = "foreign-env";
      src = pkgs.fetchFromGitHub {
        owner = "oh-my-fish";
        repo = "plugin-foreign-env";
        rev = "3ee95536106c11073d6ff466c1681cde31001383";
        sha256 = "sha256-vyW/X2lLjsieMpP9Wi2bZPjReaZBkqUbkh15zOi8T4Y=";
      };
    }];
  };
}

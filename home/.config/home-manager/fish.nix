{ pkgs, ... }:

{
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

        # home-manager
        if test -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
            fenv source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
        end

        # starship
        if status is-interactive
            starship init fish | source
        end
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

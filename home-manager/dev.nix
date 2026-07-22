# Development Home Manager module for CLI tools and dev toolchains
# Inherits essential CLI/Server configurations and adds full dev toolchains.

{ pkgs, ... }:

{
  imports = [
    ./essential.nix
    ./encryption.nix
    ./git.nix
    ./telemetry.nix
  ];

  home = {
    sessionVariables = {
      STACK_XDG = "https://github.com/commercialhaskell/stack/blob/72f0a1273dd1121740501a159988fc23df2fb362/doc/stack_root.md?plain=1#L7-L11";

      # Workaround to detect tailscale kyes
      # Setting this is not an ideal state. Because of this env ignores configs on $PWD
      # Reconsider to use trufflehog if core maintainers no longer review https://github.com/gitleaks/gitleaks/pull/1808
      BETTERLEAKS_CONFIG = "${../config/betterleaks/.betterleaks.toml}";
    };

    packages =
      (with pkgs; [
        mdcat # pipe friendly markdown viewer rather than glow
        ruby_4_0
        _7zz # `7zz` - 7zip. Command is not 7zip.

        ghq
        unstable.nixfmt
        direnv
        yazi
        hexyl # hex viewer
        sad

        # Keybindigs: https://git.sr.ht/~bptato/chawan/tree/master/item/res/config.toml
        # Don't use unstable channels until resolving https://github.com/NixOS/nixpkgs/issues/483562
        chawan # `cha`

        unstable.gurk-rs
        pastel

        # How to get the installed font names
        # fontconfig by nix: `fc-list : family style`
        fontconfig # `fc-list`, `fc-cache`

        fastfetch # active replacement of neofetch

        # For healthy Nix life
        unstable.hydra-check
        unstable.nix-tree

        unstable.somo
        unstable.typescript-go
        unstable.typos
        hyperfine
        riffdiff # `riff`
        gnumake
        unstable.betterleaks
        nushell
      ])
      ++ (with pkgs.local; [
        fzf-bind-posix-shell-history-to-git-commit-message
        git-delete-merged-branches
        todo
        ghqf
        walk
        envs
        ir
        bench_shells
        preview
        renmark
      ]);

    shellAliases = {
      "g" = "git";

      "gH" = "git show HEAD";

      # GH-897
      "ddis" = "direnv disallow";
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/direnv.nix
  programs.direnv = {
    enable = true;

    config.global = {
      # https://github.com/direnv/direnv/issues/68#issuecomment-2054033048
      hide_env_diff = true;
    };

    # Replacement of `programs.direnv.enableNixDirenvIntegration = true;`
    #
    # Make much faster, but I may add nix_direnv_watch_file in several repositories when it has `.ruby-version`
    # See following reference
    #   - https://github.com/nix-community/nix-direnv/blob/ed2cb75553b4864e3c931a48e3a2cd43b93152c5/README.md?plain=1#L368-L373
    #   - https://github.com/kachick/ruby-ulid/pull/410
    nix-direnv = {
      enable = true;
    };
  };

  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/yazi.nix
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    settings = {
      # https://github.com/sxyazi/yazi/pull/2803
      # https://github.com/nix-community/home-manager/pull/7160
      mgr = {
        sort_dir_first = true;
      };
    };
  };

  # No home-manager module exists https://github.com/nix-community/home-manager/issues/2890
  # TODO: Automate that needs to call `Install-Module -Name PSFzfHistory` first
  xdg.configFile."powershell/Microsoft.PowerShell_profile.ps1".source =
    ../config/powershell/Profile.ps1;

  # Don't use nushell Nix modules. Because of the interface and API is much unstable
  # I prefer to use stable home-manager channel. So nushell integration should be done manually
  #
  # Don't use `recursive` here. We can't expect any nushell changes for now
  xdg.configFile."nushell/env.nu".source = ../config/nushell/env.nu;
  xdg.configFile."nushell/config.nu".source = ../config/nushell/config.nu;
  xdg.configFile."nushell/unix_config.nu".source = ../config/nushell/unix_config.nu;
}

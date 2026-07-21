# Minimal CLI/Server essential module for Home Manager
# Excludes desktop/GUI applications, heavy dev toolchains (ruby, fontconfig, etc.), powershell/nushell, mdcat/dust, direnv/nixfmt, telemetry (go toolchain), and encryption tools.

{
  config,
  pkgs,
  lib,
  ...
}:

let
  hmLib = import ./lib.nix { inherit config lib; };
in
{
  _module.args = {
    inherit (hmLib) mkWritableConfig;
  };

  imports = [
    ./bash.nix
    ./zsh.nix
    ./ssh.nix
    ./git.nix
    ./editors.nix
    ./terminals.nix
    ./fzf.nix
    ./television.nix
  ];

  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/misc/xdg.nix
  xdg.enable = true;

  home = {
    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    #
    # TODO: Bump to 26.05 *carefully* once both NixOS and Home Manager 26.05 are out.
    #       This setting is similar to but not identical in purpose to NixOS’s `system.stateVersion`.
    stateVersion = "26.05";
    enableNixpkgsReleaseCheck = true;

    sessionVariables = {
      PAGER = "less";

      # https://github.com/sharkdp/bat/blob/v0.24.0/README.md?plain=1#L201-L219
      MANPAGER = "${lib.getExe pkgs.bashInteractive} -c '${lib.getExe' pkgs.util-linux "col"} -bx | ${lib.getExe pkgs.bat} -l man -p'";
      MANROFFOPT = "-c";

      # NOTE: Original comments in zsh
      # - Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
      # - Remove -X and -F (exit if the content fits on one screen) to enable it.
      #
      # Don't add -S to enable wrap
      LESS = "-F -g -i -M -R -w -X -z-4";

      # https://github.com/coreos/bugs/issues/365#issuecomment-105638617
      LESSCHARSET = "utf-8";
    };

    sessionPath = [
      # Put executable for temporary use
      "${config.xdg.dataHome}/tmpbin"
    ];

    packages =
      (with pkgs; [
        # Use `bashInteractive`, don't `bash` - https://github.com/NixOS/nixpkgs/issues/29960, https://github.com/NixOS/nix/issues/730
        bashInteractive
        zsh
        starship
        file # Especially useful to inspect the aarch and linker type for executables. # Candidates: magika

        fzf # History: CTRL+R, Walker: CTRL+T
        # fzf-git-sh for CTRL-G CTRL-{} keybinds should be manually integrated in each shell
        # Use same nixpkgs channel as same as fzf
        television # `tv`. Alt fzf
        zoxide # Used in alias `z`, alt cd/pushd. popd = `z -`, fzf-mode = `zi`

        # Used in anywhere
        coreutils
        less # container base image doesn't have less even for ubuntu official
        procps # `ps`

        findutils
        diffutils
        gnugrep
        netcat # `nc`
        dig # Alt and raw-data oriented nslookup. # Candidates: dug - https://eng-blog.iij.ad.jp/archives/27527

        git
        # gh # Don't add gh here. Only use home-manager gh module to avoid https://github.com/cli/cli/pull/5378

        # Do not specify vim and the plugins at here, it made collisions from home-manager vim module.
        # See following issues
        # - https://github.com/kachick/dotfiles/issues/280
        # - https://discourse.nixos.org/t/home-manager-neovim-collision/16963/2

        msedit # `edit`
        unstable.fresh-editor # `fresh`

        micro

        tree
        eza # alt ls
        curl
        wget
        jq
        ripgrep # `rg`
        bat # alt cat
        hexyl # hex viewer
        dysk # alt df
        fd # alt find
        bottom # `btm`, alt top
        xh # alt HTTPie
        unstable.herdr
        zellij
        sad
        pik # alt pkill
      ])
      ++ (with pkgs.local; [
        la
        lat
        p
        rg-fzf
        tree-diff
      ]);

    # You can check the candidates in `locale -a`
    # https://wiki.archlinux.jp/index.php/%E3%83%AD%E3%82%B1%E3%83%BC%E3%83%AB
    # https://github.com/nix-community/home-manager/blob/fe56302339bb28e3471632379d733547caec8103/modules/home-environment.nix#L11
    language = {
      base = "ja_JP.UTF-8";
      # Don't set another locale such as time here, it results in unstable behavior even if I set it in environment.d
      # So if you require them, they should be specified in each shell's rc file. See GH-1116 for details
    };

    # Prefer this rather than adding wrapped script to make zsh possible to complete
    # Take care if you add nushell to the Unix dependencies again
    shellAliases = {
      "g" = "git";

      # https://github.com/NixOS/nixpkgs/pull/344193
      "zed" = "zeditor";

      # https://www.reddit.com/r/NixOS/comments/yr3jje/comment/ivswbex/
      "sudoc" = "sudo --preserve-env=PATH env";

      "gH" = "git show HEAD";

      # GH-897
      "ddis" = "direnv disallow";

      # NOTE: If the logs about missing `bind` implementations are noisy and cannot be suppressed individually,
      #       adding `--disable-event unimplemented` might be required.
      #
      # Highlighting is still experimental. However, this is a core requirement for me: https://github.com/kachick/times_kachick/issues/184#issuecomment-1396670990
      "br" = "brush --enable-highlighting";
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # # https://github.com/nix-community/home-manager/blob/release-26.05/modules/misc/nix.nix
  # # NOTE: Consider ensuring flake here: `echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf`
  # nix

  programs.lesspipe.enable = true;

  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/zoxide.nix
  programs.zoxide = {
    enable = true;
  };

  xdg.dataFile."tmpbin/.keep".text = "";

  home.file.".hushlogin".text = "This file disables daily login message. Not depend on this text.";

  # Disabled by default from performance.
  # Enabling if test `man -k`: https://github.com/NixOS/nixpkgs/pull/464253#issuecomment-3568042952
  # programs.man.generateCaches = true;

  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/starship.nix
  programs.starship = {
    enable = true;

    # Don't use `settings` option to prefer my raw toml. To consider sharing it in Windows, keeping original format is best way for me.
    # Also empty `settings` avoid writing the config. See https://github.com/nix-community/home-manager/blob/381f4f8a3a5f773cb80d2b7eb8f8d733b8861434/modules/programs/starship.nix#L102C18-L102C28
  };

  # NOTE:
  #   * Setting in this variable might be unuseful, because of home-manager session variables will not be changed on GNOME except re-login
  #     Workaround is `export STARSHIP_CONFIG="$(fd --absolute-path starship.toml)"` while developing
  #   * Avoid directory setting `programs.starship.configPath = Nix Store Path`. It is prevented by home-manager validation by their use
  home.file."${config.programs.starship.configPath}".source = "${../config/starship/starship.toml}";

  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/programs/bat.nix
  programs.bat = {
    enable = true;

    config = {
      # Candidates: preview: bat --list-themes | fzf --preview='bat --theme={} --color=always flake.nix'
      theme = "Nord";

      style = "plain";

      wrap = "character";
    };
  };

  # TODO: Switch to raw config file and shared in Windows
  programs.ripgrep = {
    enable = true;
    # https://github.com/BurntSushi/ripgrep/issues/623#issuecomment-659909044
    arguments = [
      "--hidden"
      "--glob"
      "!.git"
    ];
  };
}

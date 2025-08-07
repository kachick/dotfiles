{
  pkgs, # Don't depend on edge-pkgs as possible until realize https://github.com/NixOS/nixpkgs/issues/107466,
  config,
  ...
}:

{
  imports = [ ./lima-host.nix ];

  targets.genericLinux.enable = false;

  home = {
    homeDirectory = "/Users/${config.home.username}";

    sessionVariables = {
      # * Do not specify Nix store path for zed and vscode in macOS
      #   * See linux-ci.nix for the avoiding reason of zed-editor
      #   * vscode is unfree and heavy when no binary cache
      # * `cli: install` action installs into this path in macOS
      VISUAL = "code --wait";

      BROWSER = "open";
    };

    sessionPath = [
      # Many apps installs the binary here if not used nixpkgs
      # For example: zed-editor, cloudflare-warp, vscode(symlink?)
      "/usr/local/bin"
    ];

    packages = with pkgs; [
      # https://github.com/NixOS/nixpkgs/issues/240819
      pinentry_mac

      # alacritty # Don't install macOS alacritty with nixpkgs. Alacritty often changes schema and I'm negative to use latest until https://github.com/NixOS/nixpkgs/issues/107466

      # Don't install firefox via nixpkgs for darwin, it is broken https://github.com/NixOS/nixpkgs/blob/bac526a0fe6da6b10cfe2454f62a0defdbf1d898/pkgs/applications/networking/browsers/firefox/packages.nix#L23

      # - You can use major Nerd Fonts as `pkgs.nerdfonts.override ...`
      # - Should have at least 1 composite font that includes Monospace + Japanese + Nerd fonts,
      #   because of alacritty does not have the fallback font feature. https://github.com/alacritty/alacritty/issues/957
      # - Keep fewer nerd fonts to reduce disk space

      # You can also use 0 = `Slashed zero style` with enabling `"editor.fontLigatures": "'zero'"` in vscode
      # but cannot use it in alacritty https://github.com/alacritty/alacritty/issues/50
      plemoljp-nf
      ibm-plex # For sans-serif, use plemoljp for developing

      source-han-code-jp # Includes many definitions, useful for fallback
      inconsolata
    ];
  };

  xdg = {
    configFile = {
      "karabiner/assets" = {
        source = ../config/keyboards/karabiner/assets;
        recursive = true;
      };

      "karabiner/HomeManagerInit_karabiner.json" = {
        source = ../config/keyboards/karabiner/karabiner.json;
        # https://github.com/nix-community/home-manager/issues/3090#issuecomment-2010891733
        onChange = ''
          rm -f ${config.xdg.configHome}/karabiner/karabiner.json
          cp ${config.xdg.configHome}/karabiner/HomeManagerInit_karabiner.json ${config.xdg.configHome}/karabiner/karabiner.json
          chmod u+w ${config.xdg.configHome}/karabiner/karabiner.json
        '';
      };
    };

    dataFile = {
      # https://github.com/NixOS/nixpkgs/issues/240819#issuecomment-1616760598
      # https://github.com/midchildan/dotfiles/blob/fae87a3ef327c23031d8081333678f9472e4c0ed/nix/home/modules/gnupg/default.nix#L38
      "gnupg/gpg-agent.conf".text = ''
        grab
        default-cache-ttl 604800
        max-cache-ttl 604800
        pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
      '';
    };
  };
}

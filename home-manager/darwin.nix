{
  pkgs,
  lib,
  config,
  ...
}:

# https://github.com/nix-community/home-manager/issues/414#issuecomment-427163925
lib.mkMerge [
  (lib.mkIf pkgs.stdenv.isDarwin {
    home = {
      sessionVariables = {
        # * Do not specify Nix store path for zed in macOS
        #   https://github.com/NixOS/nixpkgs/blob/bba8dffd3135f35810e9112c40ee621f4ede7cca/pkgs/by-name/ze/zed-editor/package.nix#L217-L219
        # * `cli: install` action installs into this path in macOS
        VISUAL = "zed --wait";

        BROWSER = "open";
      };

      sessionPath = [
        # Many apps installs the binary here if not used nixpkgs
        # For example: zed-editor, cloudflare-warp, vscode(symlink?)
        "/usr/local/bin"
      ];
    };

    # :)

    xdg = {
      configFile = {
        "karabiner/assets" = {
          source = ../config/karabiner/assets;
          recursive = true;
        };

        "karabiner/HomeManagerInit_karabiner.json" = {
          source = ../config/karabiner/karabiner.json;
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
  })
]

{ lib, pkgs, ... }:

{
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/helix.nix
  # keybinds: https://docs.helix-editor.com/keymap.html
  programs.helix = {
    # Enabling this may cause colisions. Do not add in packages list
    enable = true;

    settings = {
      theme = "base16_transparent";

      editor = {
        soft-wrap = {
          enable = true;
        };

        lsp = {
          display-inlay-hints = true;
          display-messages = true;
        };

        color-modes = true;
      };
    };

    # https://docs.helix-editor.com/lang-support.html
    languages = {
      language-server = {
        typos = {
          command = lib.getExe pkgs.typos-lsp;
          config.config = "${../typos.toml}";
        };
      };

      language = [
        {
          # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1563-L1570
          name = "git-commit";
          language-servers = [ "typos" ];

          # To avoid conflicting with markdown headers. Should be synced with core.commentchar
          comment-token = ";";
        }
        {
          name = "bash";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.shfmt;
            args = [
              "--language-dialect"
              "bash"
            ];
          };
        }
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.nixfmt-rfc-style;
          };
        }
      ];
    };

    ignores = [
      ".git/"
      ".direnv/"
      ".node_modules/"
    ];

    extraPackages = with pkgs; [
      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L714
      nil

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L925
      nodePackages.bash-language-server

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L207
      rust-analyzer

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L578
      gopls
      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L132-L133
      golangci-lint-langserver

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1478
      marksman

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1164
      lua-language-server

      ## Not helpful. Didin't activated?
      #
      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1202
      # nodePackages.yaml-language-server

      # # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L271
      # taplo

      ## Keep minimum for global use. Inject in each project repositories if you need these

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L714
      # nodePackages.typescript-language-server

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1547
      # https://github.com/NixOS/nixpkgs/blob/733f5a9806175f86380b14529cb29e953690c148/pkgs/development/tools/language-servers/dockerfile-language-server-nodejs/default.nix#L28
      # nodePackages.dockerfile-language-server-nodejs

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1651
      # nodePackages.graphql-language-service-cli

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L509
      # crystalline

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L870
      # solargraph # Can we prefer steep here?

      # # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1967
      # nu-lsp

      # # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1669
      # elm-language-server

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1217
      # haskell-language-server

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1260
      # zls
    ];
  };
}

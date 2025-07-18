{ lib, pkgs, ... }:

let
  # Alternative global dprint
  #   - https://github.com/dprint/dprint/issues/355
  #   - https://github.com/dprint/dprint-vscode/issues/13
  mkDprint = extension: {
    command = lib.getExe pkgs.unstable.dprint;
    args = [
      "fmt"
      "--config"
      "${../dprint.json}"
      "--stdin"
      # No need to specify all extensions, just providing a hint to detect language
      extension
    ];
  };
in
{
  # https://github.com/nix-community/home-manager/blob/release-24.11/modules/programs/helix.nix
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

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        lsp = {
          display-inlay-hints = false;
          display-messages = true;
        };

        color-modes = true;

        # like tab
        # how to move: gn, gp, <space>-b/
        # Not available with mouse click movement for now. https://github.com/helix-editor/helix/issues/4942
        bufferline = "always";

        file-picker = {
          # This option makes much confusion, actually working `false = show dotfiles but respecting .gitignore`
          hidden = false;
        };
      };

      keys =
        let
          shared_keymaps = {
            # "C-c" by helix default. And Using "C-/" is not simple. It requires Kitty keyboard protocol and be different on each terminal.
            # See https://github.com/helix-editor/helix/discussions/12899
            "C-/" = "toggle_comments"; # Such as vscode. Simply works on ghostty.
            "C-7" = "toggle_comments"; # Trick for realizing "C-/" in Windows Terminal. See https://github.com/helix-editor/helix/issues/1369#issuecomment-1749330353. And not working on ghostty.

            "C-p" = "file_picker";
            # "C-S-f" = "global_search"; # "<space>-/" by default. FIXME
          };
        in
        {
          normal = shared_keymaps // {
            space = {
              # https://github.com/helix-editor/helix/issues/6338
              # https://github.com/helix-editor/helix/discussions/7690
              H = ":toggle lsp.display-inlay-hints";
            };
          };

          insert = shared_keymaps // { };
        };
    };

    # https://docs.helix-editor.com/lang-support.html
    # https://github.com/helix-editor/helix/blob/25.01.1/languages.toml
    languages = {
      language-server = {
        # Helix cannot set common LSP. https://github.com/helix-editor/helix/discussions/8850
        # So required to manually merge language-servers for each language
        typos = {
          command = lib.getExe pkgs.unstable.typos-lsp;
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
          language-servers = [
            # "bash-language-server"
            "typos"
          ];
        }
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.nixfmt-rfc-style;
          };
          language-servers = [
            "nil" # Not using thesedays, however kept with helix default
            "nixd"
            "typos"
          ];
        }
        {
          name = "json";
          auto-format = true;
          formatter = mkDprint "json";
          language-servers = [
            "vscode-json-language-server"
            "typos"
          ];
        }
        {
          name = "jsonc";
          auto-format = true;
          formatter = mkDprint "jsonc";
          language-servers = [
            "vscode-json-language-server"
            "typos"
          ];
        }
        {
          name = "markdown";
          auto-format = true;
          formatter = mkDprint "md";
          language-servers = [
            "marksman"
            "typos"
          ];
        }
        {
          name = "yaml";
          auto-format = true;
          formatter = mkDprint "yml";
          language-servers = [
            "yaml-language-server"
            "ansible-language-server"
            "typos"
          ];
        }
        {
          name = "toml";
          auto-format = true;
          formatter = mkDprint "toml";
          language-servers = [
            "taplo"
            "typos"
          ];
        }
        {
          name = "rust";
          language-servers = [
            "rust-analyzer"
            "typos"
          ];
        }
        {
          name = "go";
          language-servers = [
            "gopls"
            "golangci-lint-lsp"
            "typos"
          ];
        }
        {
          name = "kdl";
          auto-format = true;
          formatter = mkDprint "kdl";
          language-servers = [ "typos" ];
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
      # nixd

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L925
      # bash-language-server

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L207
      rust-analyzer

      # Looks like required to enable gopls
      go_1_24
      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L578
      gopls
      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L132-L133
      golangci-lint-langserver

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1478
      marksman

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1164
      # lua-language-server

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L94
      vscode-langservers-extracted

      ## Not helpful. Didn't activated?
      #
      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L1202
      # yaml-language-server

      # # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L271
      # taplo

      ## Keep minimum for global use. Inject in each project repositories if you need these

      # https://github.com/helix-editor/helix/blob/24.03/languages.toml#L714
      # typescript-language-server

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

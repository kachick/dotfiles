{ lib, pkgs, ... }:

let
  # Alternative global dprint
  #   - https://github.com/dprint/dprint/issues/355
  #   - https://github.com/dprint/dprint-vscode/issues/13
  mkDprint = extension: {
    command = lib.getExe pkgs.dprint;
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
        # Helix cannot set common LSP. https://github.com/helix-editor/helix/discussions/8850
        # So required to manually merge language-servers for each language
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
          language-servers = [
            "bash-language-server"
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
            "nil"
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
            "markdown-oxide"
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
        {
          name = "lua";
          auto-format = true;
          formatter = {
            command = lib.getExe pkgs.stylua;
            args = [ "-" ];
          };
          language-servers = [
            "lua-language-server"
            "typos"
          ];
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

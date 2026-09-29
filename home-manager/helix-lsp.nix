{
  lib,
  pkgs,
  ...
}:

let
  # Global dprint: https://github.com/dprint/dprint/issues/355
  mkDprint =
    # Helix expands `%{buffer_name}` to the path of the active buffer.
    # We can pass an extension (e.g. "json") or `%{buffer_name}` to help dprint detect the file type.
    pathOrExtension: {
      command = lib.getExe pkgs.unstable.dprint;
      args = [
        "fmt"
        "--stdin"
        pathOrExtension
      ];
    };
in
{
  programs.helix = {
    # https://docs.helix-editor.com/lang-support.html
    # https://github.com/helix-editor/helix/blob/25.01.1/languages.toml
    languages = {
      # How to check the LSP log for debugging: https://github.com/helix-editor/helix/discussions/7203
      # `tail --follow ~/.cache/helix/helix.log`
      #
      # NOTE: Don't use `command = lib.getExe ...` for the same reason as extraPackages. Install them via dev.nix
      language-server = {
        # Helix cannot set global LSP.
        # - https://github.com/helix-editor/helix/discussions/8850
        # - https://github.com/helix-editor/helix/issues/12721
        # So required to manually merge language-servers for each language
        typos = {
          command = "typos-lsp";
          config.config = "${../typos.toml}";
        };

        # TODO: Drop to use upstream definition once Helix released 26+:
        # https://github.com/helix-editor/helix/commit/14a8d46d41a31b05c5cef6bb90489a9dccce8950
        rumdl = {
          command = "rumdl"; # Don't use absolute Nix store path for rumdl. Different versions are usually enabled on devShells.
          args = [
            "server"
          ];
        };

        # https://github.com/mhersson/mpls/blob/v0.16.0/README.md?plain=1#L218-L241
        mpls = {
          command = "mpls";
          args = [
            "--no-auto"
            "--code-style"
            "--enable-footnotes"
            "--enable-emoji"
            "--browser"
            "firefox" # chawan 0.2.1 didn't work
          ];
        };

        tsc = {
          command = "tsc";
          args = [
            "--lsp"
            "--stdio"
          ];
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
          # Helix has no built-in "zsh" language. It handles zsh files (like .zsh and .zshrc) under "bash".
          # We pass %{buffer_name} so dprint can detect bash or zsh from the file path.
          formatter = mkDprint "%{buffer_name}";
          language-servers = [
            # "bash-language-server"
            "typos"
          ];
        }
        {
          name = "nix";
          auto-format = true;
          formatter = mkDprint "nix";
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
            "mpls"
            "rumdl"
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
          formatter = mkDprint "go";
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
          name = "typescript";
          auto-format = true;
          formatter = mkDprint "typescript";
          language-servers = [
            "tsc"
            "typos"
          ];
        }
      ];
    };

    # Locally injected versions are preferred: https://github.com/nix-community/home-manager/pull/5208
    # If we can use the package in another editor or other tools, it might be better to be in home.packages
    # Adding here means I should use heavy toolsets even if the host is not for development purpose.
    extraPackages = with pkgs.unstable; [
      # TODO: Add shuck for lightweight alternative for bash-language-server

      typos-lsp

      # Used even in nixpkgs: https://github.com/NixOS/nixpkgs/commit/e9c59776b3d4824e13e9e0b9a96497bf18d0252a
      nixd

      rumdl

      # Use unstable because it depends on external documents and bundled them.
      # See https://github.com/NixOS/nixpkgs/pull/567956 for detail
      systemd-lsp
    ];
  };
}

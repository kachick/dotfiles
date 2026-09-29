{
  pkgs,
  ...
}:

let
  # Global dprint: https://github.com/dprint/dprint/issues/355
  dprint = {
    command = pkgs.unstable.dprint.meta.mainProgram;
    args = [
      "fmt"
      "--stdin"
      # Helix expands `%{buffer_name}` to the path of the active buffer.
      # dprint automatically detects the file type from the file path.
      "%{buffer_name}"
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
      # NOTE: Don't use `command = lib.getExe ...` because it hardcodes store paths into the closure
      # and ignores project devShells. Install tools via editor.nix or dev.nix to share across tools.
      # Use `pkg.meta.mainProgram` to reference the binary name from PATH without runtime dependencies.
      language-server = {
        # Helix cannot set global LSP.
        # - https://github.com/helix-editor/helix/discussions/8850
        # - https://github.com/helix-editor/helix/issues/12721
        # So required to manually merge language-servers for each language
        typos = {
          command = pkgs.unstable.typos-lsp.meta.mainProgram;
          config.config = "${../typos.toml}";
        };

        # TODO: Drop to use upstream definition once Helix released 26+:
        # https://github.com/helix-editor/helix/commit/14a8d46d41a31b05c5cef6bb90489a9dccce8950
        rumdl = {
          command = pkgs.unstable.rumdl.meta.mainProgram; # Don't use absolute Nix store path for rumdl. Different versions are usually enabled on devShells.
          args = [
            "server"
          ];
        };

        # https://github.com/mhersson/mpls/blob/v0.16.0/README.md?plain=1#L218-L241
        mpls = {
          command = pkgs.mpls.meta.mainProgram;
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
          command = pkgs.unstable.typescript_7.meta.mainProgram;
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
          # Passing %{buffer_name} lets dprint detect bash or zsh from the file path.
          formatter = dprint;
          language-servers = [
            # "bash-language-server"
            "typos"
          ];
        }
        {
          name = "nix";
          auto-format = true;
          formatter = dprint;
          language-servers = [
            "nil" # Not using thesedays, however kept with helix default
            "nixd"
            "typos"
          ];
        }
        {
          name = "json";
          auto-format = true;
          formatter = dprint;
          language-servers = [
            "vscode-json-language-server"
            "typos"
          ];
        }
        {
          name = "jsonc";
          auto-format = true;
          formatter = dprint;
          language-servers = [
            "vscode-json-language-server"
            "typos"
          ];
        }
        {
          name = "markdown";
          auto-format = true;
          formatter = dprint;
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
          formatter = dprint;
          language-servers = [
            "yaml-language-server"
            "ansible-language-server"
            "typos"
          ];
        }
        {
          name = "toml";
          auto-format = true;
          formatter = dprint;
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
          formatter = dprint;
          language-servers = [
            "gopls"
            "golangci-lint-lsp"
            "typos"
          ];
        }
        {
          name = "kdl";
          auto-format = true;
          formatter = dprint;
          language-servers = [ "typos" ];
        }
        {
          name = "typescript";
          auto-format = true;
          formatter = dprint;
          language-servers = [
            "tsc"
            "typos"
          ];
        }
      ];
    };
  };
}

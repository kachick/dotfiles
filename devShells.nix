{ pkgs, ... }:

{
  default = pkgs.mkShellNoCC {
    env = {
      # Correct pkgs versions in the nixd inlay hints
      NIX_PATH = "nixpkgs=${pkgs.path}";

      TYPOS_LSP_PATH = pkgs.lib.getExe pkgs.typos-lsp; # For vscode typos extension

      # Keep Go builds pure Go without requiring a C compiler in mkShellNoCC
      CGO_ENABLED = "0";
    };

    buildInputs =
      (with pkgs; [
        # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
        bashInteractive
        go-task
      ])
      ++ (pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux (
        (with pkgs; [
          nixd
          nixf-diagnose
          nurl
          nix-update

          shellcheck

          trivy
          skopeo

          desktop-file-utils # `desktop-file-validate` as a linter
          kanata # Enable on devshell for using the --check as a linter
        ])
        ++ (with pkgs; [
          betterleaks
          typos
          dprint
          zizmor
          rumdl
          go_1_27
        ])
        ++ (with pkgs.pinned; [
          ghadiag
        ])
        ++ (with pkgs.local; [
          nix-hash-url
        ])
        ++ (with pkgs; [
          typos-lsp # For zed-editor typos extension
        ])
      ));
  };
}

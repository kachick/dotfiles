{ pkgs, ... }:

let
  # Use latest because:
  # - typos-lsp is a third-party tool, it might have different releases with typos-cli even if both are defined in same nixpkgs channel.
  #   See https://github.com/kachick/dotfiles/commit/11bd10a13196d87f74f9464964d34f6ce33fa669#commitcomment-154399068 for detail.
  # - It will not be used in CI, it doesn't block workflows even if typos upstream introduced false-positive detection.
  typos-lsp = pkgs.unstable.typos-lsp;
in
{
  default = pkgs.mkShellNoCC {
    env = {
      # Correct pkgs versions in the nixd inlay hints
      NIX_PATH = "nixpkgs=${pkgs.path}";

      TYPOS_LSP_PATH = pkgs.lib.getExe typos-lsp; # For vscode typos extension
    };

    buildInputs =
      (with pkgs; [
        # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
        bashInteractive
        go-task
      ])
      ++ (pkgs.lib.optionals pkgs.stdenv.isLinux (
        (with pkgs; [
          nixd
          nixf-diagnose
          nurl
          nix-update

          shellcheck
          shfmt

          # We don't need to consider about treefmt1 https://github.com/NixOS/nixpkgs/pull/387745
          treefmt

          trivy
          lychee

          desktop-file-utils # `desktop-file-validate` as a linter
          kanata # Enable on devshell for using the --check as a linter
        ])
        ++ (with pkgs.unstable; [
          nixfmt # Finally used this package name again. See https://github.com/NixOS/nixpkgs/pull/425068 for detail
          gitleaks
          typos
          dprint
          zizmor
          rumdl # Available since https://github.com/NixOS/nixpkgs/pull/446292
          go_1_26
        ])
        ++ (with pkgs.my; [
          nix-hash-url
        ])
        ++ [
          typos-lsp # For zed-editor typos extension
        ]
      ));
  };
}

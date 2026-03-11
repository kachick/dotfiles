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

    buildInputs = [
      pkgs.local.ci
      # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
      pkgs.bashInteractive
    ]
    ++ (pkgs.lib.optionals pkgs.stdenv.isLinux (
      (with pkgs; [
        nixd
        nurl
        nix-update
      ])
      ++ [
        typos-lsp # For zed-editor typos extension
      ]
    ));
  };
}

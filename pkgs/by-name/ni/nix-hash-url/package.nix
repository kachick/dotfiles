{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "nix-hash-url";
  text = builtins.readFile ./nix-hash-url.bash;
  # nix includes `nix-prefetch-url`
  meta = {
    # References
    # - https://ryantm.github.io/nixpkgs/builders/fetchers/
    # - https://www.reddit.com/r/Nix/comments/171ijju/comment/k3rbx44/
    description = "Because of nurl does not support fetchurl";
  };
}

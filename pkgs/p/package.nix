{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "p";
  text = builtins.readFile ./${name}.bash;
  runtimeEnv = {
    # Intentionally avoiding use of the global NIX_PATH to prevent confusion:
    # * I deliberately don't set this env var on non-NixOS systems, even though home-manager provides a module for it:
    #   https://github.com/nix-community/home-manager/blob/7c1cefb98369cc85440642fdccc1c1394ca6dd2c/modules/misc/nix.nix#L170-L183
    # * On NixOS, it's set by default — my dotfiles assume it points to the stable channel.
    # * Some of my repos define it via flake to provide hints for nixd.
    # TODO: Can I reduce the container image size? It's currently around 400–500 MiB.
    NIX_PATH = "nixpkgs=${pkgs.unstable.path}";
  };
  meta = {
    description = "Wrapper for nix-shell";
  };
}

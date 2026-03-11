{ pkgs, config, ... }:
{
  # This module enables Cloudflare WARP.
  # While it is suitable for both servers and desktops, we separate it into a module
  # to opt-out on environments where it is unnecessary (e.g., WSL2 or other VM guests).
  #
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.11/nixos/modules/services/networking/cloudflare-warp.nix
  services.cloudflare-warp = {
    enable = true;
    # This should probably use `nixos-unstable`. But using the `nixpkgs-unstable` is okay for this package because Hydra does not test unfree packages.
    package = pkgs.unstable.cloudflare-warp;
  };

  nixpkgs.allowedUnfreePackageNames = [ "cloudflare-warp" ];
}

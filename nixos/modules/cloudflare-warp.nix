{ pkgs, inputs, ... }:
{
  # This module enables Cloudflare WARP.
  # While it is suitable for both servers and desktops, we separate it into a module
  # to opt-out on environments where it is unnecessary (e.g., WSL2 or other VM guests).
  #
  # Since flake.lock update in https://github.com/kachick/dotfiles/commit/65c4ff403ff9bb021a99998a8c92dd8b5fc4ec21,
  # we also need module changes from https://github.com/NixOS/nixpkgs/commit/89f5cbb27f144deff6d6fe0e6f17a97c1cee221f.
  # TODO: Remove this workaround and restore the default module after nixos-26.11.
  #
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/networking/cloudflare-warp.nix
  disabledModules = [ "services/networking/cloudflare-warp.nix" ];

  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/networking/cloudflare-warp.nix"
  ];

  services.cloudflare-warp = {
    enable = true;
    package = pkgs.unstable.cloudflare-warp;
  };

  nixpkgs.allowedUnfreePackageNames = [ "cloudflare-warp" ];

  # https://github.com/tailscale/tailscale/issues/4432#issuecomment-1112819111
  # https://github.com/NixOS/nixpkgs/issues/504119#issuecomment-4143108440
  networking.firewall.checkReversePath = "loose";
}

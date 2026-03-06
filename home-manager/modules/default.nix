{ overlays }:
{
  common = ../common.nix;
  desktop = ./desktop.nix;
  # All Linux (NixOS + non-NixOS)
  linux = ../linux.nix;
  # Only for non-NixOS Linux (Home Manager convention)
  genericLinux = ../genericLinux.nix;

  # Personal profile
  kachick = ./kachick.nix;

  # Platform/Environment specific
  genericUser = ../genericUser.nix;
  darwin = ../darwin.nix;
  systemd = ../systemd.nix;
  wsl = ../wsl.nix;
  lima-guest = ../lima-guest.nix;
  lima-host = ../lima-host.nix;

  overlays = {
    nixpkgs.overlays = [ overlays.default ];
  };
}

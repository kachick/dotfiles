{ overlays }:
{
  common = ../profiles/common;
  desktop = ./desktop.nix;
  # All Linux (NixOS + non-NixOS)
  linux = ../targets/linux.nix;
  # Only for non-NixOS Linux (Home Manager convention)
  genericLinux = ../targets/generic-linux.nix;

  # Personal profile
  kachick = ./kachick.nix;

  # Platform/Environment specific
  ephemeral = ../profiles/ephemeral.nix;
  darwin = ../targets/darwin.nix;
  systemd = ../services/systemd.nix;
  wsl = ../targets/wsl.nix;
  lima-guest = ../targets/lima-guest.nix;
  lima-host = ../targets/lima-host.nix;

  overlays = {
    nixpkgs.overlays = [ overlays.default ];
  };
}

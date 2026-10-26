{ overlays }:
{
  dev = ../dev.nix;
  essential = ../essential.nix;
  server = ../essential.nix;
  desktop = ./desktop.nix;
  # All Linux (NixOS + non-NixOS)
  linux = ../linux.nix;
  # Only for non-NixOS Linux (Home Manager convention)
  genericLinux = ../genericLinux.nix;

  # Personal profile
  kachick = ./kachick.nix;

  # Tools and services
  storage = ../storage.nix;
  messenger = ../messenger.nix;
  containers = ../containers.nix;

  # Platform/Environment specific
  ephemeral = ../ephemeral.nix;
  systemd = ../systemd.nix;
  wsl = ../wsl.nix;
  lima-guest = ../lima-guest.nix;
  lima-host = ../lima-host.nix;

  overlays = {
    nixpkgs.overlays = [ overlays.default ];
  };
}

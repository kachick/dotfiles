{ overlays }:
{
  profiles = {
    common = ../profiles/common;
    kachick = ../profiles/kachick.nix;
    ephemeral = ../profiles/ephemeral.nix;
  };

  targets = {
    linux = ../targets/linux.nix;
    genericLinux = ../targets/generic-linux.nix;
    darwin = ../targets/darwin.nix;
    wsl = ../targets/wsl.nix;
    lima-guest = ../targets/lima-guest.nix;
    lima-host = ../targets/lima-host.nix;
  };

  services = {
    systemd = ../services/systemd.nix;
  };

  programs = {
    desktop = ./desktop.nix;
  };

  overlays = {
    nixpkgs.overlays = [ overlays.default ];
  };
}

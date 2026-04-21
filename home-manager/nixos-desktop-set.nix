{ ... }:

{
  imports = [
    ./linux.nix
    ./lima-host.nix
    ./systemd.nix
    ./desktop.nix
    ./firefox.nix
    { targets.genericLinux.enable = false; }
  ];
}

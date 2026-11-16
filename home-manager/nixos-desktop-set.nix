{ ... }:

{
  imports = [
    ./linux.nix
    ./lima-host.nix
    ./systemd.nix
    ./desktop.nix
    ./storage.nix
    ./messenger.nix
    ./containers.nix
    ./firefox.nix
    { targets.genericLinux.enable = false; }
  ];
}

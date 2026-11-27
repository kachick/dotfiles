{ ... }:

{
  imports = [
    ./linux.nix
    ./systemd.nix
    ./desktop.nix
    ./storage.nix
    ./messenger.nix
    ./containers.nix
    ./firefox.nix
    { targets.genericLinux.enable = false; }
  ];
}

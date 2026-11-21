{ outputs, ... }:
{
  imports = [
    outputs.homeManagerModules.dev
    outputs.homeManagerModules.storage
    outputs.homeManagerModules.messenger
    outputs.homeManagerModules.containers
    ../desktop.nix
  ];
}

{ outputs, ... }:
{
  imports = [
    outputs.homeManagerModules.profiles.common
    ../programs/desktop.nix
  ];
}

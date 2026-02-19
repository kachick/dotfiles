{ outputs, ... }:
{
  imports = [
    outputs.nixosModules.common
    outputs.nixosModules.home-manager
    ../desktop
  ];

  nixpkgs.overlays = [ outputs.overlays.default ];
  _module.args.overlays = [ outputs.overlays.default ];
}

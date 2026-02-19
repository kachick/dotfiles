{ outputs, ... }:
{
  imports = [
    outputs.nixosModules.common
    ../desktop
  ];

  nixpkgs.overlays = [ outputs.overlays.default ];
  _module.args.overlays = [ outputs.overlays.default ];
}

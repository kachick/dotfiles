{
  outputs,
  pkgs,
  ...
}:

{
  imports = [
    ../configuration.nix
    outputs.nixosModules.home-manager
  ];

  # Allow specific unfree packages via predicate
  nixpkgs.allowedUnfreePackageNames = [
    "antigravity-cli"
  ];
  nixpkgs.overlays = [ outputs.overlays.default ];

  _module.args.overlays = [ outputs.overlays.default ];

  # System packages for headless development
  environment.systemPackages = [
    pkgs.local.antigravity-cli
  ];
}

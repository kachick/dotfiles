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

  # Allow unfree packages such as antigravity-cli
  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ outputs.overlays.default ];

  _module.args.overlays = [ outputs.overlays.default ];

  # System packages for headless development
  environment.systemPackages = [
    pkgs.local.antigravity-cli
  ];
}

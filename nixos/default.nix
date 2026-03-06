{
  nixpkgs,
  inputs,
  self,
  sharedOverlays,
  ...
}:

let
  system = "x86_64-linux";
  shared = {
    inherit system;
    specialArgs = {
      inherit inputs;
      outputs = self.outputs;
      overlays = {
        default = nixpkgs.lib.composeManyExtensions sharedOverlays;
      };
    };
  };
in
{
  flake.nixosConfigurations = {
    "moss" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/moss ]; });
    "algae" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/algae ]; });
    "wsl" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/wsl ]; });
  };
}

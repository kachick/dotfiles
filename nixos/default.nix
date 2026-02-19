{
  nixpkgs,
  inputs,
  outputs,
  overlays,
}:

let
  system = "x86_64-linux";
  shared = {
    inherit system;
    specialArgs = { inherit inputs outputs overlays; };
  };
in
{
  "moss" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/moss ]; });
  "algae" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/algae ]; });
  "wsl" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/wsl ]; });
}

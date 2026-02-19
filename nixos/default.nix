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
  "sample-desktop" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/sample ]; });
  "wsl" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/wsl ]; });
}

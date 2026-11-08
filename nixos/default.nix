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
  "desktop-free" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/desktop-free ]; });
  "dev-headless" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/dev-headless ]; });
  "installer" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/installer ]; });
  "wsl" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/wsl ]; });
  "sandbox" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./hosts/sandbox ]; });
}

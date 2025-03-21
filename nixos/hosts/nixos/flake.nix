# cp this_file /etc/nixos/
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    generic = {
      url = "github:kachick/dotfiles";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, ... }@attrs:
    {
      nixosConfigurations.this_host_name = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = attrs;
        modules = [ ./configuration.local.nix ];
      };
    };
}

# How to use in your flake without impure mode
# - Put this file as your /etc/nixos/flake.nix
# - Add below config in your /etc/nixos/configuration.local.nix
#   Intentionally renamed from configuration.nix, keeping original generated config would be useful for debugging
#
# { config, lib, nixpkgs, generic, ... }: {
#   imports = [ generic.nixosConfigurations.nixos.default ];
#   ...
# }
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

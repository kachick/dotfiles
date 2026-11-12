# NixOS Configuration

This directory contains NixOS system configurations.
These settings are exported as `nixosModules`, so you can inherit and reuse them from other flakes.

## Hosts and Bootstrap

List defined hostnames:

```bash
nix eval --json 'github:kachick/dotfiles#nixosConfigurations' --apply 'builtins.attrNames' | jq '.[]'
```

Using flake style is disabled in NixOS by default and [you should inject git command to use flakes](https://www.reddit.com/r/NixOS/comments/18jyd0r/cleanest_way_to_run_git_commands_on_fresh_nixos/).

**NOTICE: This command might drop all existing users except those defined in the configurations.**

```bash
nix --extra-experimental-features 'nix-command flakes' shell 'github:NixOS/nixpkgs/nixos-26.05#gitMinimal' \
	--command sudo nixos-rebuild switch \
	--flake "github:kachick/dotfiles#$(hostname)" \
	--show-trace
```

Finally, reboot the device:

```bash
sudo reboot now
```

## How to use from other flakes (Inheritance)

Here is a minimal example of `flake.nix` for your repository.
You can find a more detailed template in [nixos/hosts/sample](./hosts/sample/flake.nix).

```nix
{
  inputs = {
    dotfiles.url = "github:kachick/dotfiles";
    nixpkgs.follows = "dotfiles/nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      dotfiles,
      ...
    }@inputs:
    {
      nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # Pass 'dotfiles' as 'outputs' to specialArgs.
        # This is required for internal module cross-references.
        specialArgs = {
          inherit inputs;
          outputs = dotfiles;
        };
        modules = [
          # Desktop set (Includes common CLI, Desktop Environment, Fonts, and GUI Apps)
          dotfiles.nixosModules.desktop

          # Your machine specific config (hostname, user, filesystems, etc.)
          ./configuration.nix
        ];
      };
    };
}
```

## Development and Testing

To verify the sample configuration against the current repository state:

```bash
task test-sample-nixos
```

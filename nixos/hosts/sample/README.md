# NixOS Host Template

Standalone template inheriting `nixosModules` from this repository.

```bash
cp nixos/hosts/sample/flake.nix /path/to/repo/flake.nix
nixos-generate-config --show-hardware-config >/path/to/repo/hardware-configuration.nix

# After adjusting hostName and URL in flake.nix:
sudo nixos-rebuild switch --flake .#sample

# Verify template against current repository state:
task test-sample-nixos
```

# NixOS

```bash
# List defined hosts
nix eval --json 'github:kachick/dotfiles#nixosConfigurations' --apply 'builtins.attrNames' | jq '.[]'

# Fresh bootstrap (injects git for flakes; drops users not defined in config)
nix --extra-experimental-features 'nix-command flakes' shell 'github:NixOS/nixpkgs/nixos-26.05#gitMinimal' \
	--command sudo nixos-rebuild switch \
	--flake "github:kachick/dotfiles#$(hostname)" \
	--show-trace
sudo reboot now
```

See [hosts/sample](./hosts/sample/README.md) to inherit `nixosModules` from another flake.

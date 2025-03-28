# NixOS

List defined hostnames

```bash
nix eval --json 'github:kachick/dotfiles#nixosConfigurations' --apply 'builtins.attrNames' | jq '.[]'
```

Using flake style is disabled in NixOS by default and [you should inject git command to use flakes](https://www.reddit.com/r/NixOS/comments/18jyd0r/cleanest_way_to_run_git_commands_on_fresh_nixos/).

**NOTICE: This command might drop all existing users except which defined in configurations.**

```bash
nix --extra-experimental-features 'nix-command flakes' shell 'github:NixOS/nixpkgs/nixos-24.11#git' \
  --command sudo nixos-rebuild switch \
  --flake "github:kachick/dotfiles#$(hostname)" \
  --show-trace
```

If you are experimenting to setup NixOS just after installing from their installer and want to avoid impure mode,\
See [generic configuration](nixos/hosts/generic) for my current workaround.

This repository intentionally reverts the home-manager NixOS module.\
So, you should activate the user dotfiles with standalone home-manager even though NixOS.\
See [GH-680](https://github.com/kachick/dotfiles/issues/680) for background

```bash
passwd user
su - user
nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#user@nixos-desktop'
```

Finally, reboot the device

```bash
sudo reboot now
```

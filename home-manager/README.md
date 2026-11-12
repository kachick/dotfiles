# Home Manager

## Bootstrap on Ubuntu and Debian

```bash
# List defined configurations
nix eval --json 'github:kachick/dotfiles#homeConfigurations' --apply 'builtins.attrNames' | jq '.[]'
```

### Debian prerequisites

```bash
sudo apt update && sudo apt upgrade
sudo apt install --assume-yes curl dbus-user-session # dbus-user-session is for podman

# On WSL (reboot after setting):
echo '
[boot]
systemd=true' | sudo tee /etc/wsl.conf
```

### Install Nix and apply Home Manager

```bash
curl -fsSL https://raw.githubusercontent.com/kachick/dotfiles/main/scripts/install-nix.bash | bash

# Workaround: https://www.reddit.com/r/Nix/comments/1443k3o/comment/jr9ht5g/
mkdir -p ~/.local/state/nix/profiles
bash

NIX_CONFIG='accept-flake-config = true' nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#user@wsl-ubuntu'

# System-level config (https://github.com/kachick/dotfiles/commit/2e47c6655dc74a4a56495fdcbebb9d15b0b57313)
sudoc nix run 'github:kachick/dotfiles#apply-system'
sudoc tailscale up --ssh
```

### Podman on Ubuntu

```bash
# "shadow" in nixpkgs is not enough for rootless podman: https://github.com/NixOS/nixpkgs/issues/138423
sudo apt-get install --assume-yes uidmap

# Ensure cgroup v1 is disabled on WSL (see ../windows/WSL/README.md), then verify:
podman run public.ecr.aws/debian/debian:stable-slim cat /etc/os-release
```

## Configuration Guidelines

- Avoid `programs.<name>` modules when possible. Install packages via `home.packages` and link files in `config/` using `xdg.configFile` or `home.file` to avoid breakages from nixpkgs updates and share configs with Windows.
- Use `xdg.writableConfigFile` ([home-manager/writable-config.nix](./writable-config.nix)) for apps that modify their own config files at runtime (e.g., Zed, Ghostty, SSH).

## Inheritance

```nix
{
  inputs = {
    dotfiles.url = "github:kachick/dotfiles";
    nixpkgs.follows = "dotfiles/nixpkgs";
    home-manager.follows = "dotfiles/home-manager";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      dotfiles,
      ...
    }:
    {
      homeConfigurations."user@host" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          dotfiles.homeManagerModules.desktop
          dotfiles.homeManagerModules.linux
          { home.username = "user"; }
        ];
        extraSpecialArgs = {
          outputs = dotfiles;
        };
      };
    };
}
```

## FAQ

See also <https://github.com/kachick/dotfiles/wiki/Nix-and-home-manager>.

### Prefetch hashes without `lib.fakeHash`

```bash
# Unpacked NAR hash (fetchFromGitHub, fetchzip, fetchTarball)
iets prefetch --unpack https://github.com/github/gh-actions-lock/archive/refs/tags/v0.4.1.tar.gz

# Raw file hash (fetchurl)
iets prefetch https://pkg.cloudflareclient.com/pool/noble/main/c/cloudflare-warp/cloudflare-warp_2024.6.497-1_amd64.deb

# Built-in alternative (adds file to local Nix store)
nix store prefetch-file --json <URL> | jq -r .hash
```

### Convert JSON to Nix

[Reference](https://gist.github.com/spencerpogo/0538252ed4b82d65e59115075369d34d?permalink_comment_id=4999658#gistcomment-4999658)

```bash
nix-instantiate --eval -E 'builtins.fromJSON (builtins.readFile ./dprint.jsonc)' | nixfmt
```

### Make `home.file` executable

[Reference](https://github.com/nix-community/home-manager/blob/15043a65915bcc16ad207d65b202659e4988066b/modules/xsession.nix#L195C1-L197)

```nix
home.file."path".executable = true;
```

### Inspect store paths and resolve collisions

- Store path inspection: `nix path-info <pkg>`
- Mixing channels: <https://github.com/nix-community/home-manager/issues/1538#issuecomment-1265293260>
- Package collisions ([GH-280](https://github.com/kachick/dotfiles/issues/280), [Discourse](https://discourse.nixos.org/t/home-manager-neovim-collision/16963/2)): remove the duplicate entry from `home.packages` when a Home Manager module already provides it.

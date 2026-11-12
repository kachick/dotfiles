# Home Manager Configuration

This directory contains Home Manager configurations.
These settings are exported as `homeManagerModules`.

## Bootstrap on Ubuntu and Debian

List defined configurations:

```bash
nix eval --json 'github:kachick/dotfiles#homeConfigurations' --apply 'builtins.attrNames' | jq '.[]'
```

### Ubuntu

1. Install and configure Nix:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/kachick/dotfiles/main/scripts/install-nix.bash | bash
   ```

1. If you forgot to add something during the installation phase, manually add it.\
   Some configurations require a reboot to be applied, such as `trusted-users`.

1. Make sure there is a nix directory that is used in the home-manager.\
   This is a workaround, See [the thread](https://www.reddit.com/r/Nix/comments/1443k3o/comment/jr9ht5g/?utm_source=reddit&utm_medium=web2x&context=3) for details

   ```bash
   mkdir -p ~/.local/state/nix/profiles
   ```

1. Restart current shell to load Nix as a PATH

   ```bash
   bash
   ```

1. Apply dotfiles

   ```bash
   NIX_CONFIG='accept-flake-config = true' nix run 'github:kachick/dotfiles#home-manager' -- switch -b backup --flake 'github:kachick/dotfiles#user@wsl-ubuntu'
   ```

1. Apply system level dotfiles with [sudo for nix command](https://github.com/kachick/dotfiles/commit/2e47c6655dc74a4a56495fdcbebb9d15b0b57313)

   ```bash
   sudoc nix run 'github:kachick/dotfiles#apply-system'
   ```

1. Enable tailscale ssh if required

   ```bash
   sudoc tailscale up --ssh
   ```

#### Podman on Ubuntu

1. Install uidmap without Nix for use of podman even if the podman will be installed from nixpkgs

   - "shadow" in nixpkg is not enough for podman - <https://github.com/NixOS/nixpkgs/issues/138423>

   ```bash
   sudo apt-get install --assume-yes uidmap
   ```

1. Make sure the cgroup v1 is disabled if you are on WSL, See [the docs](../windows/WSL/README.md)

1. Make sure you can run containers as `podman run public.ecr.aws/debian/debian:stable-slim cat /etc/os-release`

### Debian

After installing missing tools, you can complete the same steps as on Ubuntu

```bash
sudo apt update
sudo apt upgrade
sudo apt install --assume-yes curl
sudo apt install --assume-yes dbus-user-session # For podman
```

Remember to set special config and reboot if you are on WSL

```bash
echo '
[boot]
systemd=true' | sudo tee /etc/wsl.conf
```

## Notes on configuration files

Do not use per-package `programs.<name>` modules. Install raw packages via `home.packages` and link config files using `xdg.configFile` or `home.file` to avoid breakages from nixpkgs updates.

### Where to put settings?

For tools used only in Nix, you can write settings directly in Nix files here.

However, for tools shared with other OSs like Windows (e.g., `starship.toml`), I keep raw configuration files in the root `config/` directory.
In these cases, Home Manager creates a symlink to the raw file.

This makes it easy to use the same settings in environments that do not have Nix.

## How to use from other flakes (Inheritance)

```nix
{
  inputs = {
    dotfiles.url = "github:kachick/dotfiles";
    nixpkgs.follows = "dotfiles/nixpkgs";
    home-manager.follows = "dotfiles/home-manager";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      dotfiles,
      ...
    }:
    {
      homeConfigurations."user@host" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          # Standard Desktop Linux set (Includes essential & dev CLI settings)
          dotfiles.homeManagerModules.desktop
          # Add Linux specific tools
          dotfiles.homeManagerModules.linux

          # Machine specific overrides
          { home.username = "user"; }
        ];
        # Required for internal module cross-references
        extraSpecialArgs = {
          outputs = dotfiles;
        };
      };
    };
}
```

---

## FAQ

Also read <https://github.com/kachick/dotfiles/wiki/Nix-and-home-manager>

## How to get sha256 without `lib.fakeHash`?

Use `iets prefetch`:

```bash
# Fetch unpacked NAR hash (for fetchFromGitHub, fetchzip, or fetchTarball)
iets prefetch --unpack https://github.com/github/gh-actions-lock/archive/refs/tags/v0.4.1.tar.gz

# Fetch raw file hash (for fetchurl)
iets prefetch https://pkg.cloudflareclient.com/pool/noble/main/c/cloudflare-warp/cloudflare-warp_2024.6.497-1_amd64.deb
```

Nix also provides a built-in command:

```bash
nix store prefetch-file --json <URL> | jq -r .hash
```

`iets prefetch` is preferred here because it prints only the SRI hash to standard output without adding the file to the local Nix store.

## How to convert JSON to Nix?

See [this comment](https://gist.github.com/spencerpogo/0538252ed4b82d65e59115075369d34d?permalink_comment_id=4999658#gistcomment-4999658)

```bash
nix-instantiate --eval -E 'builtins.fromJSON (builtins.readFile ./dprint.jsonc)' | nixfmt
```

## How to make executable? `.text =` makes a sym, that links to non executable file

```nix
home.file."path".executable = true;
```

Read <https://github.com/nix-community/home-manager/blob/15043a65915bcc16ad207d65b202659e4988066b/modules/xsession.nix#L195C1-L197> as an example

## How to know and get the paths inside a pkg?

`nix path-info` is a way, installing iTerm2 shell integration used it. Access /nix/store~ path, and `ls` helps you.

## How to mix _-unstable and release-_ for different packages?

See <https://github.com/nix-community/home-manager/issues/1538#issuecomment-1265293260>

## How to resolve collisions?

It maybe occurred with home-manager module and manually specified `pkgs.*`, try to remove the added package.

- <https://github.com/kachick/dotfiles/issues/280>
- <https://discourse.nixos.org/t/home-manager-neovim-collision/16963/2>

## Writable config management (HomeManagerInit pattern)

To keep configurations writable for applications that have their own settings UI or require frequent manual adjustments (e.g., Zed, Ghostty, SSH), a pattern is used involving `onChange`.

A module in `home-manager/writable-config.nix` automates this pattern. See the comments in that file for more details.

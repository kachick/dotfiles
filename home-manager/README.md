# Home Manager Configuration

This directory contains Home Manager configurations.
These settings are exported as `homeManagerModules`.

## How to use from other flakes (Inheritance)

```nix
{
  inputs.dotfiles.url = "github:kachick/dotfiles";

  outputs = { self, nixpkgs, home-manager, dotfiles, ... }: {
    homeConfigurations."user@host" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        # Standard Desktop Linux set (Includes common CLI settings)
        dotfiles.homeManagerModules.desktop
        # Add Linux specific tools
        dotfiles.homeManagerModules.linux
        # Add kachick's personal profile (Optional)
        dotfiles.homeManagerModules.kachick

        # Machine specific overrides
        { home.username = "user"; }
      ];
      extraSpecialArgs = { outputs = dotfiles; };
    };
  };
}
```

### Exported Modules

- `dotfiles.homeManagerModules.desktop`: Recommended for GUI users. Includes `common`.
- `dotfiles.homeManagerModules.common`: Common CLI tool settings.
- `dotfiles.homeManagerModules.linux`: Linux specific tool settings (Podman, etc.).
- `dotfiles.homeManagerModules.kachick`: kachick's personal profile (Git, GPG).

---

## FAQ

Also read <https://github.com/kachick/dotfiles/wiki/Nix-and-home-manager>

## How to get sha256 without `lib.fakeHash`?

```bash
nurl https://github.com/kachick/selfup v1.2.0
nix-hash-url https://pkg.cloudflareclient.com/pool/noble/main/c/cloudflare-warp/cloudflare-warp_2024.6.497-1_amd64.deb
```

## How to convert JSON to Nix?

See [this comment](https://gist.github.com/spencerpogo/0538252ed4b82d65e59115075369d34d?permalink_comment_id=4999658#gistcomment-4999658)

```bash
nix-instantiate --eval -E 'builtins.fromJSON (builtins.readFile ./dprint.json)' | nixfmt
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

## I cannot find dot files in the macOS Finder

<https://apple.stackexchange.com/a/250646>, consider to use [nix-darwin](https://github.com/LnL7/nix-darwin/blob/16c07487ac9bc59f58b121d13160c67befa3342e/modules/system/defaults/finder.nix#L8-L14)

## How to resolve collisions?

It maybe occurred with home-manager module and manually specified `pkgs.*`, try to remove the added package.

- <https://github.com/kachick/dotfiles/issues/280>
- <https://discourse.nixos.org/t/home-manager-neovim-collision/16963/2>

## Writable config management (HomeManagerInit pattern)

To keep configurations writable for applications that have their own settings UI or require frequent manual adjustments (e.g., Zed, Ghostty, Karabiner, SSH), we use a pattern involving `onChange`.

We provide a helper `hmInit` in `home-manager/lib.nix` that automates this pattern. See the comments in that file for more details.

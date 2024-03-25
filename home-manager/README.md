# FAQ

Also read <https://github.com/kachick/dotfiles/wiki/Nix-and-home-manager>

## How to get sha256 without `lib.fakeSha256`?

```bash
nix-prefetch-git --url https://github.com/oh-my-fish/plugin-foreign-env.git --rev 3ee95536106c11073d6ff466c1681cde31001383 --quiet | jq .hash
```

## How to convert JSON to Nix?

See [this comment](https://gist.github.com/Scoder12/0538252ed4b82d65e59115075369d34d?permalink_comment_id=4999658#gistcomment-4999658)

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

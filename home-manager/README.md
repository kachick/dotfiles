# Home Manager FAQ

This document provides answers to frequently asked questions about using Home Manager in this repository.
For more general information, see the [Nix and Home Manager wiki page](https://github.com/kachick/dotfiles/wiki/Nix-and-home-manager).

---

### How do I get a file's SHA256 hash?

Instead of using a fake hash like `lib.fakeHash`, you can calculate the real hash using tools like `nurl` or `nix-hash-url`.

```bash
# For a GitHub repository
nurl https://github.com/kachick/selfup v1.2.0

# For a direct URL
nix-hash-url https://pkg.cloudflareclient.com/pool/noble/main/c/cloudflare-warp/cloudflare-warp_2024.6.497-1_amd64.deb
```

### How do I convert a JSON file to a Nix expression?

You can use `nix-instantiate` combined with `nixfmt` to convert a JSON file into a formatted Nix expression. See [this comment](https://gist.github.com/spencerpogo/0538252ed4b82d65e59115075369d34d?permalink_comment_id=4999658#gistcomment-4999658) for more context.

```bash
nix-instantiate --eval -E 'builtins.fromJSON (builtins.readFile ./dprint.json)' | nixfmt
```

### How do I make a managed file executable?

When creating a file with `home.file.<path>.text`, it creates a symlink to a non-executable file in the Nix store. To make it executable, set the `executable` option to `true`.

```nix
home.file."path".executable = true;
```

See [this `xsession` module](https://github.com/nix-community/home-manager/blob/15043a65915bcc16ad207d65b202659e4988066b/modules/xsession.nix#L195-L197) for an example.

### How do I find the paths of files inside a Nix package?

You can use `nix path-info` to inspect the contents of a package. This is useful, for example, when setting up the iTerm2 shell integration. Once you have the store path (e.g., `/nix/store/...`), you can use `ls` to explore its contents.

### How do I mix packages from different Nixpkgs channels (e.g., stable and unstable)?

Refer to the solution described in [this Home Manager issue comment](https://github.com/nix-community/home-manager/issues/1538#issuecomment-1265293260).

### How can I show dotfiles in the macOS Finder?

By default, Finder hides files that start with a dot. You can change this setting to always show them. See [this Stack Exchange answer](https://apple.stackexchange.com/a/250646) for instructions. If you use `nix-darwin`, you can configure this declaratively via the [`system.defaults.finder` module](https://github.com/LnL7/nix-darwin/blob/16c07487ac9bc59f58b121d13160c67befa3342e/modules/system/defaults/finder.nix#L8-L14).

### How do I resolve package collisions?

Collisions can occur when a package is enabled through a Home Manager module and also manually included in `home.packages`. To resolve this, try removing the package from `home.packages`.

See these discussions for more details:

- <https://github.com/kachick/dotfiles/issues/280>
- <https://discourse.nixos.org/t/home-manager-neovim-collision/16963/2>

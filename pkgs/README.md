# What are these packages

- Tiny tools by me, they may be rewritten with another language.
- Nix packages that are not yet included in [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs)
- Aliases across multiple shells if it unfits for native shell alias

## Do not

- Do not apply shebang, set in the script. It will be applied in `pkgs.writeShellApplication`
- Do not directly implement in pkgs/default.nix to keep simple list
- Do not directly implement non tiny scripts in *.nix to apply better editor/formatter support
- Don't just use `fileset.gitTracked root`, then always rebuild even if just changed the README.md
- Don't use `fileset.gitTracked` for now, [nix-update does not yet support it](https://github.com/Mic92/nix-update/issues/335)

## How to update

- I don't consider automated updating versions in these package for now
- I can't ignore hash updating for dependabot PRs, for go and rust. Currently resolved with `nix-update --flake pname --version=skip`

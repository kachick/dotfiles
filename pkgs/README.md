# What are these packages

- Tiny tools by me, they may be rewritten with another language.
- Nix packages that are not yet included in [NixOS/nixpkgs](https://github.com/NixOS/nixpkgs)
- Aliases across multiple shells if it unfits for native shell alias

## Do not

- Do not apply shebang, set in the script. It will be applied in `pkgs.writeShellApplication`
- Do not directly implement in pkgs/default.nix to keep simple list
- Do not directly implement non tiny scripts in *.nix to apply better editor/formatter support

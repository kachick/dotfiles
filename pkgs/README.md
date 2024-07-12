# What are these packages

- Tiny tools by me, they may be rewritten with another language.
- Aliases across multiple shells

## Do not

- Do not apply shebang, set in the script. It will be applied in `pkgs.writeShellApplication`
- Do not directly implement in pkgs/default.nix to keep simple list
- Do not directly implement non tiny scripts in *.nix to apply better editor/formatter support

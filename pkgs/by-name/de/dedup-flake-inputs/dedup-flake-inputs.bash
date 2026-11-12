flake-edit --non-interactive follow --transitive
dprint fmt flake.nix
nix flake lock

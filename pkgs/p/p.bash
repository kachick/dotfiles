# * Needless to trim the default command, nix-shell only runs last command if given multiple.
# * Don't specify another shell such as zsh, the impure mode prefers rc defined environments. It makes confusions when using different version of same package
nix-shell -I nixpkgs="https://github.com/NixOS/nixpkgs/archive/${NIXPKGS_REF:-nixos-unstable}.tar.gz" --packages "$@"

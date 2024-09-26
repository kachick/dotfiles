# Needless to trim the default command, nix-shell only runs last command if given multiple.
nix-shell -I nixpkgs="https://github.com/NixOS/nixpkgs/archive/${NIXPKGS_REF:-nixos-unstable}.tar.gz" --command 'zsh' --packages "$@"

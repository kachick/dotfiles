# * Needless to trim the default command, nix-shell only runs last command if given multiple.
# * NOTE: Specifying another shell such as zsh, the impure mode prefers rc defined environments. It might make confusions when using different version of same package
nix-shell --command zsh --packages "$@"

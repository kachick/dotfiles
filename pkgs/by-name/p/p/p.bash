# * Needless to trim the default command, nix-shell only runs last command if given multiple.
# * NOTE: Specifying another shell such as zsh, the impure mode prefers rc defined environments. It might make confusions when using different version of same package

has_dash_dash=false
packages=()
command_args=()

for arg in "$@"; do
	if [ "$has_dash_dash" = true ]; then
		command_args+=("$arg")
	elif [ "$arg" = "--" ]; then
		has_dash_dash=true
	else
		packages+=("$arg")
	fi
done

if [ "$has_dash_dash" = true ] && [ "${#command_args[@]}" -gt 0 ]; then
	cmd=$(printf '%q ' "${command_args[@]}")
	exec nix-shell --packages "${packages[@]}" --run "$cmd"
else
	exec nix-shell --command zsh --packages "$@"
fi

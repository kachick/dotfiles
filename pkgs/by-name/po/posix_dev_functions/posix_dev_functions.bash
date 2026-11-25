# shellcheck shell=bash
# Shared between bash and zsh for development environments; see posix_shared_functions.bash for conventions.

gx() {
	local target
	target="$('@git_x@' menu "$@")" || return 1
	if [ -n "$target" ]; then
		cd "$target" || return 1
	fi
}

gch() {
	fc -nrl 1 | '@git_x@' commit-from-history
}

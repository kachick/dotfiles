# shellcheck shell=bash
# Shared between bash and zsh for development environments; see posix_shared_functions.bash for conventions.

repo() {
	local target
	if [ $# -ge 1 ] && [ "$1" = "get" ]; then
		shift
		target="$('@git_x@' get "$@")" || return 1
	else
		local query_repoonly=""
		if [ $# -ge 1 ] && [ -n "$1" ]; then
			query_repoonly="$(printf '%s\n' "$1" | '@git_x@' gh-reponame)"
		fi
		target="$('@git_x@' repo-fzf "$query_repoonly")" || return 1
	fi
	if [ -n "$target" ]; then
		cd "$target" || return 1
	fi
}

wt() {
	local target
	target="$('@git_x@' wt _cd-helper "$@")" || return 1
	if [ -n "$target" ]; then
		cd "$target" || return 1
	fi
}

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

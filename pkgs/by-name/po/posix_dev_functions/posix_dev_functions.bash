# shellcheck shell=bash
# Shared between bash and zsh for development environments; see posix_shared_functions.bash for conventions.

cdrepo() {
	local query_repoonly=""
	if [ $# -ge 1 ] && [ -n "$1" ]; then
		query_repoonly="$(printf '%s\n' "$1" | '@git_x@' gh-reponame)"
	fi
	local -r target="$('@git_x@' repo-fzf "$query_repoonly")"
	if [ -n "$target" ]; then
		cd "$target" || return 1
	fi
}

getrepo() {
	local target_dir
	target_dir="$('@git_x@' get "$@")" || return 1
	if [ -n "$target_dir" ]; then
		cd "$target_dir" || return 1
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

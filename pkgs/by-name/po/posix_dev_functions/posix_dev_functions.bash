# shellcheck shell=bash
# Shared between bash and zsh for development environments; see posix_shared_functions.bash for conventions.

cdrepo() {
	local query_repoonly=""
	if [ $# -ge 1 ] && [ -n "$1" ]; then
		query_repoonly="$(printf '%s\n' "$1" | '@gitx@' gh-reponame)"
	fi
	local -r target="$('@gitx@' ghq-fzf "$query_repoonly")"
	if [ -n "$target" ]; then
		cd "$target" || return 1
	fi
}

getrepo() {
	local trust=0
	local repo_spec=""
	while [ $# -gt 0 ]; do
		case "$1" in
		--trust)
			trust=1
			;;
		-*)
			echo "Unknown option: $1" >&2
			return 2
			;;
		*)
			if [ -n "$repo_spec" ]; then
				echo "Usage: getrepo [--trust] <repo_spec>" >&2
				return 2
			fi
			repo_spec="$1"
			;;
		esac
		shift
	done

	if [ -z "$repo_spec" ]; then
		echo "Usage: getrepo [--trust] <repo_spec>" >&2
		return 2
	fi

	local repo_dir
	repo_dir="$('@ghq@' get --clean-bare "$repo_spec")" || return 1
	if [ -z "$repo_dir" ]; then
		echo "Failed to resolve cloned repository path for: $repo_spec" >&2
		return 1
	fi

	local target_dir
	if [ "$trust" -eq 1 ]; then
		target_dir="$('@gitx@' init-clean-bare --trust "$repo_dir")" || return 1
	else
		target_dir="$('@gitx@' init-clean-bare "$repo_dir")" || return 1
	fi

	cd "$target_dir" || return 1
}

wt() {
	local target
	target="$('@gitx@' wt _cd-helper "$@")" || return 1
	if [ -n "$target" ]; then
		cd "$target" || return 1
	fi
}

gch() {
	fc -nrl 1 | '@gitx@' commit-from-history
}

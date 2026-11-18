# shellcheck shell=bash
# This file should keep compatibility for both bash and zsh even if specified only the `shell=bash`.
# However shellcheck does not support multiple specifier for the directive.
# Additionally both .sh and .dash does not cover the modern shell features.

# How to stop blinking cursor in Linux console?
# => https://web.archive.org/web/20220318101402/https://nutr1t07.github.io/post/disable-cursor-blinking-on-linux-console/
disable_blinking_cursor() {
	echo -en '\033[?16;5;140c'
}

adjust_to_linux_vt() {
	avoid_tofu
	disable_blinking_cursor
}

cdwin() {
	if ! command -v wslpath &>/dev/null; then
		# TODO: Consider inject only in WSL environment
		echo "This command works only in WSL2"
	fi

	cd "$(wslpath "$1")" || return 1
}

cdrepo() {
	local query_repoonly=""
	if [ $# -ge 1 ] && [ -n "$1" ]; then
		query_repoonly="$(printf '%s\n' "$1" | '@reponame@')"
	fi
	local -r target="$('@ghqf@' "$query_repoonly")"
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
		target_dir="$('@git_init_clean_bare@' --trust "$repo_dir")" || return 1
	else
		target_dir="$('@git_init_clean_bare@' "$repo_dir")" || return 1
	fi

	cd "$target_dir" || return 1
}

gwt() {
	local target
	target="$('@git_wt@' select "$@")" || return 1
	if [ -n "$target" ]; then
		cd "$target" || return 1
	fi
}

cdtemp() {
	local word
	if [ $# -lt 1 ]; then
		word="$('@gopass@' pwgen --xkcd --sep '-' --one-per-line 2 | '@coreutils@/bin/head' -1)"
	else
		word="$1"
	fi

	cd "$('@coreutils@/bin/mktemp' --tmpdir --directory "cdtemp.$word.XXX")" || return 1
}

cdnix() {
	if [ $# -lt 1 ]; then
		echo "Specify Nix injected command you want to dive"
		return 2
	fi
	# TODO: Check exit code and Nix or not
	local -r command="$(command -v "$1")"
	cd "$('@coreutils@/bin/dirname' "$('@coreutils@/bin/dirname' "$('@coreutils@/bin/readlink' --canonicalize "$command")")")" || return 1
}

gch() {
	fc -nrl 1 | '@fzf_bind_shell_hist@'
}

avoid_tofu() {
	export LANG=C
	export STARSHIP_CONFIG='@starship@/share/starship/presets/plain-text-symbols.toml'
	export ZELLIJ_CONFIG_FILE="$XDG_CONFIG_HOME/zellij/simplified-ui.kdl"
}

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

# Why plain mktemp instead of gopass pwgen:
# Previously used gopass xkcd words for readable directory names without adding wordlist packages.
# Keep essential/server shell helpers free of encryption tool dependencies; standard mktemp provides 6 random characters.
cdtemp() {
	local template
	if [ $# -lt 1 ]; then
		template="cdtemp.XXXXXX"
	else
		template="cdtemp.$1.XXX"
	fi

	cd "$('@coreutils@/bin/mktemp' --tmpdir --directory "$template")" || return 1
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

avoid_tofu() {
	export LANG=C
	export STARSHIP_CONFIG='@starship@/share/starship/presets/plain-text-symbols.toml'
	export ZELLIJ_CONFIG_FILE="$XDG_CONFIG_HOME/zellij/simplified-ui.kdl"
}

# Avoid spawning external commands in precmd; include parent dir to tell worktrees apart across repos.
set_win_title() {
	local dir="$PWD"
	local title

	while [ "$dir" != "/" ] && [ "${dir%/}" != "$dir" ]; do
		dir="${dir%/}"
	done

	if [ "$dir" = "/" ]; then
		title="/"
	else
		local base="${dir##*/}"
		local parent_dir="${dir%/*}"
		if [ -z "$parent_dir" ] || [ "$parent_dir" = "$dir" ]; then
			title="$dir"
		else
			local parent="${parent_dir##*/}"
			title="$parent/$base"
		fi
	fi

	printf '\033]0; %s \007' "$title"
}

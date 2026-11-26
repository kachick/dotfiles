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

# Why diceware instead of gopass pwgen:
# Use the local zero-dependency diceware binary so essential/server shells get readable temp directory names without pulling in encryption tools.
cdtemp() {
	local words template
	words="$('@diceware@' -words 2 -count 1)" || return 1
	if [ $# -lt 1 ]; then
		template="cdtemp.${words}.XXX"
	else
		template="cdtemp.$1.${words}.XXX"
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
	sync_herdr_space_repo
}

# Report repository name for worktrees to herdr's sidebar without blocking precmd.
sync_herdr_space_repo() {
	if [ "${HERDR_ENV:-}" != "1" ] || [ -z "${HERDR_WORKSPACE_ID:-}" ]; then
		return 0
	fi
	if [ "$PWD" = "${_herdr_last_pwd:-}" ]; then
		return 0
	fi
	_herdr_last_pwd="$PWD"

	local workspace_id="$HERDR_WORKSPACE_ID"
	local herdr_bin="${HERDR_BIN_PATH:-herdr}"
	local pwd_now="$PWD"

	# Double-subshell avoids shell job-control notices in both bash and zsh.
	(
		(
			common_dir="$(git -C "$pwd_now" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || common_dir=""
			toplevel="$(git -C "$pwd_now" rev-parse --show-toplevel 2>/dev/null)" || toplevel=""

			if [ -n "$common_dir" ] && [ -n "$toplevel" ]; then
				while [ "$common_dir" != "/" ] && [ "${common_dir%/}" != "$common_dir" ]; do
					common_dir="${common_dir%/}"
				done
				common_base="${common_dir##*/}"
				if [ "$common_base" = ".git" ] || [ "$common_base" = ".bare" ]; then
					parent="${common_dir%/*}"
					repo="${parent##*/}"
				else
					repo="${common_base%.git}"
				fi
				toplevel_base="${toplevel##*/}"
			else
				repo=""
				toplevel_base=""
			fi

			if [ -n "$repo" ] && [ "$repo" != "$toplevel_base" ]; then
				"$herdr_bin" workspace report-metadata "$workspace_id" --source shell --token "repo=$repo"
			else
				"$herdr_bin" workspace report-metadata "$workspace_id" --source shell --clear-token repo
			fi
		) >/dev/null 2>&1 &
	)
}

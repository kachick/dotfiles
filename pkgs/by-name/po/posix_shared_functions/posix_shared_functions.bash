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
	local -r query_repoonly="$(echo "$1" | '@reponame@')"
	local -r repo="$('@ghqf@' "$query_repoonly")"
	if [ -n "$repo" ]; then
		cd "$('@ghq@' list --full-path --exact "$repo")" || return 1
	fi
}

getrepo() {
	'@ghq@' get "$1" && cdrepo "$1"
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

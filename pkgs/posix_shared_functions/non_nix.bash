# Actually this file is not a bash script, but dash mode is unuseful. Expecting mostly bash code will work even in zsh...

disable_blinking_cursor() {
	echo -en '\033[?16;5;140c'
}

cdwin() {
	if ! command -v wslpath &>/dev/null; then
		# TODO: Consider inject only in WSL environment
		echo "This command works only in WSL2"
	fi

	# shellcheck disable=SC2164
	cd "$(wslpath "$1")"
}

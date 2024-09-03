cdnix() {
	if [ $# -lt 1 ]; then
		echo "Specify Nix injected command you want to dive"
		return 2
	fi
	# TODO: Check exit code and Nix or not
	local -r command="$(command -v "$1")"
	# shellcheck disable=SC2164
	cd "$(dirname "$(dirname "$(readlink --canonicalize "$command")")")"
}

cdwin() {
	if ! command -v wslpath &>/dev/null; then
		echo "This command works only in WSL2"
	fi

	# shellcheck disable=SC2164
	cd "$(wslpath "$1")"
}

disable_blinking_cursor() {
	echo -en '\033[?16;5;140c'
}

# Actually this file is not a bash script, but dash mode is unuseful. Expecting mostly bash code will work even in zsh...

cdnix() {
	if [ $# -lt 1 ]; then
		echo "Specify Nix injected command you want to dive"
		return 2
	fi
	# TODO: Check exit code and Nix or not
	local -r command="$(command -v "$1")"
	# shellcheck disable=SC2164
	cd "$(dirname "$(dirname "$(readlink "$command")")")"
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

# TODO: Consider to inject Nix path into fzf complemetion commands for making secure and robustness
# However it maybe unuseful, because of different version maybe used in each repo...

# No need adding for `cargo-make`, it require subcommand as `cargo-make make`. I'm avoiding the style
_fzf_complete_makers() {
	_fzf_complete --multi --reverse --prompt="makers> " --nth 1 -- "$@" < <(
		makers --list-all-steps | rg --regexp='^\w+ -'
	)
}

_fzf_complete_makers_post() {
	cut --delimiter=' ' --fields=1
}

_fzf_complete_task() {
	_fzf_complete --multi --reverse --prompt="task> " -- "$@" < <(
		task --list-all | rg --regexp='^\* (.+)' --replace='$1'
	)
}

_fzf_complete_task_post() {
	rg --regexp='(\S+?): ' --replace='$1'
}

_fzf_complete_zellij() {
	_fzf_complete --multi --reverse --prompt="zellij> " --ansi --nth 1 -- "$@" < <(
		zellij list-sessions
	)
}

_fzf_complete_zellij_post() {
	cut --delimiter=' ' --fields=1
}

# Actually this file is not a bash script, but dash mode is unuseful. Expecting mostly bash code will work even in zsh...

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

# TODO: Consider to inject Nix path into fzf complemetion commands for making secure and robustness
# However it maybe unuseful, because of different version maybe used in each repo...

# NOTE: You should remember difference of bash and zsh for the arguments
# https://rcmdnk.com/blog/2015/05/15/computer-linux-mac-zsh/
# And add prefix ___fzf_ for shared function to avoid conflict. It should be used in _fzf_ in each bash and zsh

# No need adding for `cargo-make`, it requires subcommand as `cargo-make make`. I'm avoiding the style
_fzf_complete_makers() {
	_fzf_complete --multi --reverse --prompt="makers> " --nth 1 -- "$@" < <(
		# Don't use `--output-format autocomplete`, it truncates task description
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

___fzf_complete_zellij_all_sessions() {
	_fzf_complete --multi --reverse --prompt="zellij> " --ansi --nth 1 -- "$@" < <(
		zellij list-sessions
	)
}

___fzf_complete_zellij_active_sessions() {
	_fzf_complete --multi --reverse --prompt="zellij(active)> " --ansi --nth 1 -- "$@" < <(
		zellij list-sessions | rg --invert-match --fixed-strings -e 'EXITED'
	)
}

_fzf_complete_zellij_post() {
	cut --delimiter=' ' --fields=1
}

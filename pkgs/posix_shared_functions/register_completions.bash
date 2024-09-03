complete -F _fzf_complete_makers -o default -o bashdefault makers
complete -F _fzf_complete_task -o default -o bashdefault task

_fzf_complete_zellij() {
	local -r subcmd="${COMP_WORDS[COMP_CWORD - 1]}"
	if [[ "$subcmd" == 'kill-session' ]]; then
		___fzf_complete_zellij_active_sessions
	else
		___fzf_complete_zellij_all_sessions
	fi

	case "$subcmd" in
	kill-session) ___fzf_complete_zellij_active_sessions ;;
	attach | delete-session) ___fzf_complete_zellij_all_sessions ;;
	*) _zellij ;;
	esac
}

# Required to be defined just before complete
_fzf_complete_zellij_post() {
	cut --delimiter=' ' --fields=1
}

complete -F _fzf_complete_zellij -o default -o bashdefault zellij

_fzf_complete_zellij() {
	local -r subcmd=${1#* }
	if [[ "$subcmd" == kill-session* ]]; then
		___fzf_complete_zellij_active_sessions
	else
		___fzf_complete_zellij_all_sessions
	fi
}

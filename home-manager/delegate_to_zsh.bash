# shellcheck shell=bash
# Auto-switch interactive top-level, login, or zellij bash sessions to zsh.
# Inspired by Arch Wiki's Fish setup:
# https://wiki.archlinux.org/title/fish#Setting_fish_as_interactive_shell_only
#
# Called from programs.bash.initExtra after Home Manager's interactive guard.
# Args:
#   $1: path to zsh binary
#   $2: path to ps binary

delegate_to_zsh() {
	local -r zsh_bin="$1"
	local -r ps_bin="$2"

	# Skip non-interactive shells, non-TTY stdin, and -c command invocations.
	if [[ $- != *i* || ! -t 0 || -n ${BASH_EXECUTION_STRING:-} ]]; then
		return 0
	fi

	# Fail-safe: stay in bash if zsh is unavailable.
	if [[ ! -x "$zsh_bin" ]]; then
		return 0
	fi

	local is_login=false
	if shopt -q login_shell; then
		is_login=true
	fi

	local should_check_parent=false
	local require_parent=""
	if [[ ${SHLVL:-} == 1 ]] || "$is_login"; then
		# Apps started from an existing shell (like herdr with shell_mode = "login") pass SHLVL >= 1,
		# so checking login_shell catches login panes even when SHLVL is 2 or higher.
		should_check_parent=true
	elif [[ -n ${ZELLIJ:-} ]]; then
		# zellij starts non-login $SHELL panes with inherited SHLVL >= 1.
		# Checking $ZELLIJ first avoids spawning ps for normal nested bash or nix develop.
		should_check_parent=true
		require_parent="zellij"
	fi

	if ! "$should_check_parent"; then
		return 0
	fi

	local parent_comm=""
	if ((PPID > 0)); then
		# Container environments (e.g. podman exec) can have PPID=0 where ps fails.
		parent_comm="$("$ps_bin" --no-header --pid="$PPID" --format=comm 2>/dev/null || true)"
	fi

	if [[ -n "$require_parent" ]]; then
		[[ "$parent_comm" == "$require_parent" ]] || return 0
	elif [[ "$parent_comm" == "zsh" ]]; then
		return 0
	fi

	if "$is_login"; then
		exec "$zsh_bin" --login
	fi
	exec "$zsh_bin"
}

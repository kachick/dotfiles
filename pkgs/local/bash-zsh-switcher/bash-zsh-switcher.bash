# Don't delegate shell execution before interactive shell checks.
# Auto-switch to Zsh if Bash is the login shell.
# Inspired by Arch Wiki's Fish setup:
# https://wiki.archlinux.org/title/fish#Setting_fish_as_interactive_shell_only
#
# --- Optimization & Cross-Platform Compatibility ---
# The order of these checks matters for three reasons:
# 1. Performance: Prioritize internal checks to minimize external 'ps' calls.
# 2. Cross-Platform Reliability: 'ps' acts differently across systems.
#    Even with 'procps' from nixpkgs, the package is not the same on Linux and Darwin, though it has the same name in Nixpkgs.
# 3. Container Environments: $PPID can be 0 in environments like podman exec, which causes 'ps' to fail.
# This approach is also beneficial since Bash isn't typically a login shell on macOS.
if [[ -z "${BASH_EXECUTION_STRING}" && "${SHLVL}" == 1 && $PPID -gt 0 && "$(@ps@ --no-header --pid=$PPID --format=comm)" != "zsh" ]]; then
	if shopt -q login_shell; then
		LOGIN_OPTION='--login'
	else
		unset LOGIN_OPTION
	fi
	exec @zsh@ ${LOGIN_OPTION+"$LOGIN_OPTION"}
fi

if [[ -n "${BRUSH_VERSION+this_shell_is_brush_not_the_bash}" ]]; then
	# - We can't simply use $BRUSH_VERSION for this purpose because of it is a shell variable.
	#   Starship can only handle environment variables in env_var module.
	# - Remember remaining this even if you run bash/zsh on brush. SHLVL helps it.
	# - Don't set built-in $STARSHIP_SHELL variable, remaining on bash should be reasonable for now
	export STARSHIP_BRUSH_INDICATOR='brush'
else
	# https://github.com/Bash-it/bash-it/blob/00062bfcb6c6a68cd2c9d2c76ed764e01e930e87/plugins/available/history-substring-search.plugin.bash
	if [[ ${SHELLOPTS} =~ (vi|emacs) ]]; then
		bind '"\e[A":history-substring-search-backward'
		bind '"\e[B":history-substring-search-forward'
	fi
fi

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
	debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
xterm-color | *-256color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
	if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
		# We have color support; assume it's compliant with Ecma-48
		# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
		# a case would tend to support setf rather than setaf.)
		color_prompt=yes
	else
		color_prompt=
	fi
fi

if [ "$color_prompt" = yes ]; then
	PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\[\033[01;34m\]\w\[\033[00m\]\$ '
else
	PS1='${debian_chroot:+($debian_chroot)}\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm* | rxvt*)
	PS1="\[\e]0;${debian_chroot:+($debian_chroot)} \w\a\]$PS1"
	;;
*) ;;

esac

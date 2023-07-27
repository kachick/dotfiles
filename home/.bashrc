#!/usr/bin/env bash

# shellcheck disable=SC1090,SC1091

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# Should have home.nix only...?
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_HOME="$HOME/.local/share"

export INPUTRC="$XDG_CONFIG_HOME"/readline/inputrc

mkdir -p "$XDG_STATE_HOME"/bash
HISTFILE="$XDG_STATE_HOME"/bash/history

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=100000
HISTFILESIZE=4200000

# See https://github.com/kachick/times_kachick/issues/237
#
# Avoid nix provided bash on nix-shell makes broken bind, complete, color_prompt
# Following part of ps... did referer to https://github.com/NixOS/nix/issues/3862#issuecomment-1611837272,
# because non nested bash does not make this problem.
# e.g
#   cd ../
#   rm ./the_repo/.envrc # Avoid direnv injection
#   cd ./the_repo
#   nix develop # the executed nix-shell does NOT have problems, so you can wrap as starship
#   bash # this nested bash HAS problems without following ps... condition.
if [[ -n "$IN_NIX_SHELL" && "$(ps -o uid= $PPID)" -eq "$UID" ]]; then
  in_nested_nix_bash="true"
fi

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

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

if [ "$color_prompt" = yes ] && [ -z "$in_nested_nix_bash" ]; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\w\$ '
fi
unset color_prompt force_color_prompt

if [ -z "$in_nested_nix_bash" ]; then
  # If this is an xterm set the title to user@host:dir
  case "$TERM" in
  xterm* | rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)} \w\a\]$PS1"
    ;;
  *) ;;

  esac
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  (test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)") || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  #alias dir='dir --color=auto'
  #alias vdir='vdir --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix && [ -z "$in_nested_nix_bash" ]; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"; fi

# https://github.com/Bash-it/bash-it/blob/00062bfcb6c6a68cd2c9d2c76ed764e01e930e87/plugins/available/history-substring-search.plugin.bash
if [[ ${SHELLOPTS} =~ (vi|emacs) ]]; then
  bind '"\e[A":history-substring-search-backward'
  bind '"\e[B":history-substring-search-forward'
fi

if command -v fzf-share >/dev/null && [ -z "$in_nested_nix_bash" ]; then
  source "$(fzf-share)/key-bindings.bash"
  source "$(fzf-share)/completion.bash"
fi

# # Delegate history search with "Up arrow key" to fzf
# bind '"\C-\e[A":"\C-r"'

if [ -n "$in_nested_nix_bash" ]; then
  # readlink - https://iww.hateblo.jp/entry/20131108/dash
  PS1="${IN_NIX_SHELL} - $(readlink /proc/$$/exe)\n$PS1"
else
  eval "$(starship init bash)"
fi

# https://github.com/starship/starship/blob/0d98c4c0b7999f5a8bd6e7db68fd27b0696b3bef/docs/uk-UA/advanced-config/README.md#change-window-title
function set_win_title() {
  echo -ne "\033]0; $(basename "$PWD") \007"
}
# shellcheck disable=SC2034
starship_precmd_user_func="set_win_title"

eval "$(zoxide init bash)"

. ~/.aliases.sh

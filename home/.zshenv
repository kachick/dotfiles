#
# Defines environment variables.
#

# https://qiita.com/vintersnow/items/7343b9bf60ea468a4180
# zmodload zsh/zprof && zprof

export PATH
export MANPATH
# -U: keep only the first occurrence of each duplicated value
# ref. http://zsh.sourceforge.net/Doc/Release/Shell-Builtin-Commands.html#index-typeset
typeset -U PATH path MANPATH manpath

# ignore /etc/zprofile, /etc/zshrc, /etc/zlogin, and /etc/zlogout
# ref. http://zsh.sourceforge.net/Doc/Release/Files.html
# ref. http://zsh.sourceforge.net/Doc/Release/Options.html#index-GLOBALRCS
unsetopt GLOBAL_RCS
# copied from /etc/zprofile
# system-wide environment settings for zsh(1)
if [ -x /usr/libexec/path_helper ]; then
  eval $(/usr/libexec/path_helper -s)
fi

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:=$HOME/.config}"
# Do NOT manage .zshenv(thisfile) in the dir.
export ZDOTDIR="${ZDOTDIR:=$XDG_CONFIG_HOME/zsh}"

export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_HOME="$HOME/.local/share"

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ ("$SHLVL" -eq 1 && ! -o LOGIN) && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

if [ -e /home/kachick/.nix-profile/etc/profile.d/nix.sh ]; then . /home/kachick/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
if [ -e "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"; fi

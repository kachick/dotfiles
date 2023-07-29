#
# Executes commands at the start of an interactive session.
#

# Do NOT use (( $+commands[sheldon] )) here. It made 1.5x slower zsh execution :<
if type 'sheldon' > /dev/null; then
  eval "$(sheldon source)"
fi

# zsh-history-substring-search
typeset -g HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=blue,bold'
typeset -g HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'
typeset -g HISTORY_SUBSTRING_SEARCH_FUZZY='true'
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

. "$XDG_CONFIG_HOME/homemade/.aliases.sh"

setopt correct
unsetopt BEEP
# These pickup disanling does not work...
# unsetopt LIST_BEEP
# unsetopt HIST_BEEP

# History
HISTSIZE=100000
SAVEHIST=4200000
mkdir -p "$XDG_STATE_HOME/zsh"
HISTFILE="$XDG_STATE_HOME/zsh/history"
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_no_store
setopt EXTENDED_HISTORY
setopt share_history
bindkey '^R' history-incremental-pattern-search-backward
bindkey '^S' history-incremental-pattern-search-forward

# Don't use nvm. It is heavy.

# Didn't work? I'm okay to use as `rtx exec ruby@3.2.1 -- irb` for now.`
eval "$($XDG_DATA_HOME/rtx/bin/rtx activate -s zsh)"

_dumppath() {
  local -r dump_dir="$XDG_CACHE_HOME/zsh"
  mkdir -p "$dump_dir"

  echo "$dump_dir/zcompdump-$ZSH_VERSION"
}

# Hack to redump(?) for optimization
# See below references
# * https://github.com/kachick/dotfiles/issues/154
# * https://gist.github.com/ctechols/ca1035271ad134841284
# * https://memo.kkenya.com/zsh_speed_up/
_compinit_with_interval() {
  local -r dump_path="$(_dumppath)"
  local -r threshold="$((60 * 60 * 12))"

  autoload -Uz compinit

  if [ ! -e "$dump_path" ] || [ "$(("$(date +"%s")" - "$(date -r "$dump_path" +"%s")"))" -gt "$threshold" ]; then
    compinit -d "$dump_path"
    touch "$dump_path"
  else
    # if there are new functions can be omitted by giving the option -C.
    compinit -C -d "$dump_path"
  fi
}
_compinit_with_interval

case ${OSTYPE} in
darwin*)
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
  ;;
esac

if command -v fzf-share >/dev/null; then
  source "$(fzf-share)/key-bindings.zsh"
  source "$(fzf-share)/completion.zsh"
fi

eval "$(starship init zsh)"

# https://github.com/starship/starship/blob/0d98c4c0b7999f5a8bd6e7db68fd27b0696b3bef/docs/uk-UA/advanced-config/README.md#change-window-title
function set_win_title() {
  echo -ne "\033]0; $(basename "$PWD") \007"
}
precmd_functions+=(set_win_title)

eval "$(zoxide init zsh)"

eval "$(direnv hook zsh)"

# Do not save history if it was failed
zshaddhistory() { whence ${${(z)1}[1]} >| /dev/null || return 1 }

# https://qiita.com/vintersnow/items/7343b9bf60ea468a4180
# if (which zprof >/dev/null 2>&1); then
#   zprof
# fi

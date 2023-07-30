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

eval "$($XDG_DATA_HOME/rtx/bin/rtx activate -s zsh)"

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

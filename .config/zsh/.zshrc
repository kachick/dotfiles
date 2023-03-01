#
# Executes commands at the start of an interactive session.
#

# https://qiita.com/eumesy/items/3bb39fc783c8d4863c5f
# in ~/.zshenv, executed `unsetopt GLOBAL_RCS` and ignored /etc/zshrc
[ -r /etc/zshrc ] && . /etc/zshrc

eval "$(sheldon source)"

# zsh-history-substring-search
typeset -g HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND='fg=blue,bold'
typeset -g HISTORY_SUBSTRING_SEARCH_GLOBBING_FLAGS='i'
typeset -g HISTORY_SUBSTRING_SEARCH_FUZZY='true'
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

. ~/.aliases.sh

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

# Hack to redump(?) for optimization
# See below references
# * https://github.com/kachick/dotfiles/issues/154
# * https://gist.github.com/ctechols/ca1035271ad134841284
# * https://memo.kkenya.com/zsh_speed_up/
_compinit_with_interval() {
  local -r dump_dir="$XDG_CACHE_HOME/zsh"
  mkdir -p "$dump_dir"

  local -r dump_path="$dump_dir/zcompdump-$ZSH_VERSION"
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

update_tools() {
  case ${OSTYPE} in
  linux*)
    sudo apt update && sudo apt upgrade
    ;;
  darwin*)
    brew update
    brew upgrade
    ;;
  esac

  nix-channel --update
  sheldon lock --update
  if command -v rtx; then
    rtx self-update
  fi
}

# Keep under 120ms...!
bench_zsh() {
  hyperfine 'zsh -i -c exit'
}

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

# https://qiita.com/vintersnow/items/7343b9bf60ea468a4180
# if (which zprof >/dev/null 2>&1); then
#   zprof
# fi

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

# History
HISTSIZE=100000
SAVEHIST=4200000
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

# initialise completions with ZSH's compinit
autoload -Uz compinit
compinit

# https://qiita.com/vintersnow/items/7343b9bf60ea468a4180
# if (which zprof > /dev/null 2>&1) ;then
#   zprof
# fi

update_tools() {
  case ${OSTYPE} in
  linux*)
    sudo apt update && sudo apt upgrade
    ;;
  esac

  nix-channel --update
  sheldon lock --update
}

# I would keep `not heavy` to lunch shell.
# So do not forget to measure. If any loading changes are added.
# ~~ Keep sec <= 0.5 ~~
bench_zsh() {
  # Below useful benchmark script is taken from https://qiita.com/vintersnow/items/7343b9bf60ea468a4180. Thanks!
  for i in $(seq 1 10); do time zsh -i -c exit; done
}

case ${OSTYPE} in
darwin*)
  test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
  ;;
esac

if [ -n "${commands[fzf - share]}" ]; then
  source "$(fzf-share)/key-bindings.zsh"
  source "$(fzf-share)/completion.zsh"
fi

eval "$(starship init zsh)"

# https://github.com/starship/starship/blob/0d98c4c0b7999f5a8bd6e7db68fd27b0696b3bef/docs/uk-UA/advanced-config/README.md#change-window-title
function set_win_title() {
  echo -ne "\033]0; $(basename "$PWD") \007"
}
precmd_functions+=(set_win_title)

eval "$(direnv hook zsh)"

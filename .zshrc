#
# Executes commands at the start of an interactive session.
#

# https://qiita.com/eumesy/items/3bb39fc783c8d4863c5f
# in ~/.zshenv, executed `unsetopt GLOBAL_RCS` and ignored /etc/zshrc
[ -r /etc/zshrc ] && . /etc/zshrc

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...


# My useful commands!
alias git-switch-default='git checkout develop 2>/dev/null || git checkout development 2>/dev/null || git checkout main 2>/dev/null || git checkout trunk 2>/dev/null || git checkout master 2>/dev/null'
alias git-current-branch='git symbolic-ref --short HEAD'
alias git-remote-upsteram="git remote | grep -E '^upstream$'|| git remote | grep -E '^origin$'"
# https://github.com/kyanny/git-delete-merged-branches/pull/6
alias git-delete-merged-branches="git branch --merged | grep -vE '((^\*)|^ *(main|master|develop|development|trunk)$)' | xargs -I % git branch -d %"
alias git-cleanup-branches="git-switch-default && git pull $(git-remote-upsteram) $(git-current-branch) && git fetch $(git-remote-upsteram) --tags --prune && git-delete-merged-branches"


#
# Workaround for: https://github.com/sorin-ionescu/prezto/issues/1744
#
export HISTFILE="${ZDOTDIR:-$HOME}/.zhistory" # The path to the history file.

# Don't use asdf-ruby, at least https://github.com/asdf-vm/asdf-ruby/issues/204 and https://github.com/asdf-vm/asdf-ruby/pull/205 rsolved.
source /usr/local/share/chruby/chruby.sh
chruby ruby-3.0.0

# Don't use nvm. It is heavy.

# https://asdf-vm.com/#/core-manage-asdf
. $HOME/.asdf/asdf.sh
# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit
compinit

# https://qiita.com/vintersnow/items/7343b9bf60ea468a4180
# if (which zprof > /dev/null 2>&1) ;then
#   zprof
# fi

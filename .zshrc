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

# My useful commands!
alias git-switch-default='git checkout develop 2>/dev/null || git checkout development 2>/dev/null || git checkout main 2>/dev/null || git checkout trunk 2>/dev/null || git checkout master 2>/dev/null'
alias git-current-branch='git symbolic-ref --short HEAD'
alias git-remote-upsteram="git remote | grep -E '^upstream$'|| git remote | grep -E '^origin$'"
# https://github.com/kyanny/git-delete-merged-branches/pull/6
alias git-delete-merged-branches="git branch --merged | grep -vE '((^\*)|^ *(main|master|develop|development|trunk)$)' | xargs -I % git branch -d %"
alias git-cleanup-branches='git-switch-default && git pull $(git-remote-upsteram) $(git-current-branch) && git fetch $(git-remote-upsteram) --tags --prune && git-delete-merged-branches'

# Overriding the definition of `modules/history/init.sh`
HISTSIZE=100000
SAVEHIST=4200000

# Don't use asdf-ruby, at least https://github.com/asdf-vm/asdf-ruby/issues/204 rsolved.
source /usr/local/share/chruby/chruby.sh
chruby 3.0

# Don't use nvm. It is heavy.

# https://asdf-vm.com/#/core-manage-asdf
. $HOME/.asdf/asdf.sh
# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit
compinit

path=(
    `npm bin --global` # https://qiita.com/joe-re/items/12987cdeee506dea3889
    ${path}
)

# https://qiita.com/vintersnow/items/7343b9bf60ea468a4180
# if (which zprof > /dev/null 2>&1) ;then
#   zprof
# fi

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

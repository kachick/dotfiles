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

# Don't use nvm. It is heavy.

# https://asdf-vm.com/#/core-manage-asdf
. $HOME/.asdf/asdf.sh
# append completions to fpath
fpath=(${ASDF_DIR}/completions $fpath)
# initialise completions with ZSH's compinit
autoload -Uz compinit
compinit

# This section will take few seconds... :<
#
# ref: https://qiita.com/joe-re/items/12987cdeee506dea3889
# path=(
#     `npm bin --global`
#     ${path}
# )

# https://qiita.com/vintersnow/items/7343b9bf60ea468a4180
# if (which zprof > /dev/null 2>&1) ;then
#   zprof
# fi

# Clean room of declaring variables
() {
  local brew_prefix

  case ${OSTYPE} in
    linux*)
      brew_prefix='/home/linuxbrew/.linuxbrew'
      ;;
    darwin*)
      brew_prefix='/opt/homebrew'
      ;;
  esac

  export PATH="${brew_prefix}/bin:$PATH"

  # Not yet tracked the conclusion of https://github.com/asdf-vm/asdf-ruby/issues/204.
  source "${brew_prefix}/opt/chruby/share/chruby/chruby.sh"
  chruby 3.1
}

update_tools() {
  case ${OSTYPE} in
    linux*)
      sudo apt update && sudo apt upgrade
      ;;
  esac

  # Update brew itself. Included in upgrade option...?
  brew update

  # Docs say `Upgrade everything`
  brew upgrade

  asdf update
  asdf plugin update --all

  zprezto-update
}

# Might be needed around `corepack enable`.
# https://github.com/asdf-vm/asdf-nodejs/issues/42#issuecomment-1136701667
yarn() {
  command yarn "$@"
  if [ "$1" = global ]; then
    asdf reshim nodejs
  fi
}

case ${OSTYPE} in
	darwin*)
		test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
		;;
esac

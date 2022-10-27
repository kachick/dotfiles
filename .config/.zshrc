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

. ~/.aliases.sh

# Overriding the definition of `modules/history/init.sh`
HISTSIZE=100000
SAVEHIST=4200000

# Don't use nvm. It is heavy.

# https://asdf-vm.com/#/core-manage-asdf
if [ -r "$HOME/.asdf/asdf.sh" ]; then
  . "$HOME/.asdf/asdf.sh"
else
  # brew command makes slow? Then considert to extarct to .zshrc.local
  . "$(brew --prefix asdf)/libexec/asdf.sh"
fi

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

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

eval "$(starship init zsh)"

# For Crystal with libssl issue. ref: https://github.com/kachick/times_kachick/issues/188
export PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$(brew --prefix openssl@3)/lib/pkgconfig"


eval "$(direnv hook zsh)"

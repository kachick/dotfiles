#!/usr/bin/env bash

set -eux

# Keep idempotent as possible

install_brew() {
  which brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

add_brew_path() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # https://docs.brew.sh/Homebrew-on-Linux
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -r ~/.bash_profile && echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >>~/.bash_profile
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >>~/.profile
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    # https://docs.brew.sh/Installation
    mkdir homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew
    eval "$(homebrew/bin/brew shellenv)"
    brew update --force --quiet
    chmod -R go-w "$(brew --prefix)/share/zsh"
  elif [[ "$OSTYPE" == "freebsd"* ]]; then
    echo 'brew does not support FreeBSD'
  else
    echo 'Running on unknown platform. Might be windows? Use WSL2'
  fi
}

install_base_dependencies_for_linux() {
  sudo apt-get install -y build-essential procps curl file git

  # Required to build ruby
  sudo apt-get install -y zlib1g-dev
}

install_tools_with_brew() {
  brew install gcc git coreutils tig tree curl wget \
    zsh nushell starship asdf \
    pkg-config openssl@1.1 openssl@3 \
    jq gh ripgrep fzf fd sqlite postgresql imagemagick pngquant

  # Might need some setup after brew install

  "$(brew --prefix)/opt/fzf/install"
}

add_asdf_path() {
  # https://asdf-vm.com/guide/getting-started.html#_3-install-asdf

  test -r ~/.bash_profile && (
    echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >>~/.bash_profile &&
      echo -e "\n. $(brew --prefix asdf)/etc/bash_completion.d/asdf.bash" >>~/.bash_profile
  )

  # TODO: This automated adding to public_dotfiles. It is not good!
  #
  # `ZDOTDIR` might not be appear in bash, keeping the code as note
  # official: test -r ${ZDOTDIR:-~}/.zshrc && echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >>${ZDOTDIR:-~}/.zshrc
  # test -r ~/.zshrc && echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >>~/.zshrc

  # shellcheck source=/dev/null
  source "$(brew --prefix asdf)/libexec/asdf.sh"
}

required_asdf_plugins() {
  # java is needed in early stage when I added scala, kotlin, clojure
  # Using rg for ensuring PCRE. Do not consider grep/ggrep...
  rg --only-matching --no-line-number '^\S+' '.tool-versions'

  echo ruby
  echo crystal
}

missing_asdf_plugins() {
  # What is `comm`
  # https://stackoverflow.com/a/2696111/1212807
  # https://atmarkit.itmedia.co.jp/ait/articles/1703/31/news027.html
  comm -23 <(required_asdf_plugins | sort) <(asdf plugin list | sort)
}

install_asdf_plugins() {
  missing_asdf_plugins | while read -r plugin; do
    if [ "$plugin" == 'dprint' ]; then
      asdf plugin-add dprint https://github.com/asdf-community/asdf-dprint
    else
      asdf plugin add "$plugin"
    fi
  done
}

install_asdf_managed_tools() {
  # When faced ruby with OpenSSL issues, look at https://github.com/kachick/times_kachick/issues/180
  RUBY_CONFIGURE_OPTS=--with-openssl-dir="$(brew --prefix openssl@3)" asdf install ruby latest
  # RUBY_CONFIGURE_OPTS=--with-openssl-dir="$(brew --prefix openssl@1.1)" asdf install ruby 3.0.4
  # RUBY_CONFIGURE_OPTS=--with-openssl-dir="$(brew --prefix openssl@1.1)" asdf install ruby 2.7.6

  PKG_CONFIG_PATH="${PKG_CONFIG_PATH-}"
  PKG_CONFIG_PATH="$PKG_CONFIG_PATH:$(brew --prefix openssl@3)/lib/pkgconfig" asdf install crystal latest

  asdf install
}

make_symlinks() {
  local dotfile

  for dotfile in ./.config/.??*; do
    # https://linuxjm.osdn.jp/info/GNU_coreutils/coreutils-ja_86.html
    ln --symbolic --verbose --backup --relative --no-dereference --target-directory="$HOME" "$dotfile"
  done
}

# Experimental
make_nushell_as_login_shell() {
  grep '\/nu$' /etc/shells || which nu | sudo tee -a /etc/shells
  chsh -s "$(which nu)"
}

make_symlinks
install_brew
brew --prefix || add_brew_path

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  install_base_dependencies_for_linux
fi

install_tools_with_brew # Includes asd

# Wait to prefer nushell until https://github.com/nushell/nushell/issues/1616 resolved
# make_nushell_as_login_shell

which asdf || add_asdf_path
install_asdf_plugins
install_asdf_managed_tools

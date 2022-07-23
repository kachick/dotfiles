#!/bin/bash

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

install_brew_dependencies_for_linux() {
  sudo apt-get install build-essential procps curl file git
}

install_tools_with_brew() {
  brew install git coreutils tig tree curl wget \
    nushell zsh asdf \
    openssl@1.1 openssl@3 \
    jq gh ripgrep sqlite postgresql imagemagick pngquant

  # Might need some setup after brew install
}

add_asdf_path() {
  # https://asdf-vm.com/guide/getting-started.html#_3-install-asdf

  test -r ~/.bash_profile && (
    echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >>~/.bash_profile &&
      echo -e "\n. $(brew --prefix asdf)/etc/bash_completion.d/asdf.bash" >>~/.bash_profile
  )

  # `ZDOTDIR` might not be appear in bach, keeping the code as note
  # official: test -r ${ZDOTDIR:-~}/.zshrc && echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >>${ZDOTDIR:-~}/.zshrc
  test -r ~/.zshrc && echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >>~/.zshrc

  # shellcheck source=/dev/null
  source "$(brew --prefix asdf)/libexec/asdf.sh"
}

required_asdf_plugins() {
  # java is needed in early stage when I added scala, kotlin, clojure
  grep -Po '^\S+' '.tool-versions'
}

missing_asdf_plugins() {
  # What is `comm`
  # https://stackoverflow.com/a/2696111/1212807
  # https://atmarkit.itmedia.co.jp/ait/articles/1703/31/news027.html
  comm -23 <(required_asdf_plugins | sort) <(asdf plugin list | sort)
}

install_asdf_plugins() {
  missing_asdf_plugins | while read -r plugin; do
    asdf plugin add "$plugin"
  done
}

install_asdf_managed_tools() {
  asdf install

  # When faced an ruby with OpenSSL issue, look at https://github.com/kachick/times_kachick/issues/180
  # Following scripts might run
  # ASDF_RUBY_BUILD_VERSION=v20220721 RUBY_CONFIGURE_OPTS=--with-openssl-dir=$(brew --prefix openssl@3) asdf install ruby 3.1.2
  # ASDF_RUBY_BUILD_VERSION=v20220721 RUBY_CONFIGURE_OPTS=--with-openssl-dir=$(brew --prefix openssl@1.1) asdf install ruby 3.0.4
  # ASDF_RUBY_BUILD_VERSION=v20220721 RUBY_CONFIGURE_OPTS=--with-openssl-dir=$(brew --prefix openssl@1.1) asdf install ruby 2.7.6
}

make_symlinks() {
  local dotfile

  for dotfile in ./.config/.??*; do
    # https://linuxjm.osdn.jp/info/GNU_coreutils/coreutils-ja_86.html
    ln --symbolic --verbose --interactive --backup --relative --no-dereference --target-directory="$HOME" "$dotfile"
  done
}

# Experimental
make_nushell_as_login_shell() {
  which nu | sudo tee -a /etc/shells
  chsh -s "$(which nu)"
}

make_symlinks
install_brew
brew --prefix || add_brew_path

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  install_brew_dependencies_for_linux
fi

install_tools_with_brew # Includes asdf
make_nushell_as_login_shell
which asdf || add_asdf_path
install_asdf_plugins
install_asdf_managed_tools

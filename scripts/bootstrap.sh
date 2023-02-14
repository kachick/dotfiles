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
    zsh bash nushell starship asdf direnv \
    openssl@1.1 openssl@3 \
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

# I feel rust does not scope other installers as asdf :<s
install_rust() {
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
}

# Experimental
make_nushell_as_login_shell() {
  grep '\/nu$' /etc/shells || which nu | sudo tee -a /etc/shells
  chsh -s "$(which nu)"
}

./scripts/make_symlinks.bash
install_brew
brew --prefix || add_brew_path

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  install_base_dependencies_for_linux
fi

install_tools_with_brew # Includes asdf

# Wait to prefer nushell until https://github.com/nushell/nushell/issues/1616 resolved
# make_nushell_as_login_shell

which asdf || add_asdf_path
./scripts/install_asdf-plugins.bash
./scripts/install_asdf_managed_tools.bash
which rust || install_rust

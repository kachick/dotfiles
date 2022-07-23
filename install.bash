#!/bin/bash

set -eux

# Keep idempotent as possible

brew_install() {
  which brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  brew --prefix || add_brew_path

  brew install git coreutils tig tree curl wget \
    zsh sheldon \
    asdf openssl@1.1 openssl@3 \
    jq gh ripgrep sqlite postgresql imagemagick pngquant

  # Might need some setup after brew install
}

add_brew_path() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # https://docs.brew.sh/Homebrew-on-Linux
    test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
    test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    test -r ~/.bash_profile && echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >>~/.bash_profile
    echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >>~/.profile
    sudo apt-get install build-essential procps curl file git
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

required_asdf_plugins() {
  # java is needed in early stage when I added scala, kotlin, clojure

  cat <<EOD
ruby
crystal
nodejs
deno
bun
dprint
elm
golang
java
EOD
}

missing_asdf_plugins() {
  # What is `comm`
  # https://stackoverflow.com/a/2696111/1212807
  # https://atmarkit.itmedia.co.jp/ait/articles/1703/31/news027.html
  comm -23 <(required_asdf_plugins | sort) <(asdf plugin list | sort)
}

# `asdf install` simply installs and respects current `.tool-versions`. However it takes a long time for my global list.
# And having some dependencies as JVM. (I didn't check it actually make problem or not in `asdf install`)
# So provided this omitted version for now. Consider dropping this in future.
asdf_omitted_install() {
  missing_asdf_plugins | while read -r plugin; do
    asdf plugin add "$plugin"

    if [ "$plugin" != 'java' ] && [ "$plugin" != 'ruby' ]; then
      asdf install "$plugin" latest
    fi

    # asdf global is needless except java. Because .tool-versions is managed in same repository.
  done

  # asdf will skip installed versions with exit `0`. So needless as `(asdf list ruby | grep '3.1.2') || asdf install...`

  # ref: https://github.com/kachick/times_kachick/issues/180
  ASDF_RUBY_BUILD_VERSION=v20220721 RUBY_CONFIGURE_OPTS=--with-openssl-dir=$(brew --prefix openssl@3) asdf install ruby 3.1.2
  ASDF_RUBY_BUILD_VERSION=v20220721 RUBY_CONFIGURE_OPTS=--with-openssl-dir=$(brew --prefix openssl@1.1) asdf install ruby 3.0.4
  ASDF_RUBY_BUILD_VERSION=v20220721 RUBY_CONFIGURE_OPTS=--with-openssl-dir=$(brew --prefix openssl@1.1) asdf install ruby 2.7.6

  # https://github.com/halcyon/asdf-java/tree/master/data
  asdf install java adoptopenjdk-16.0.2+7
  asdf global java adoptopenjdk-16.0.2+7
}

brew_install
asdf_omitted_install

# When faced an ruby with OpenSSL issue, look at https://github.com/kachick/times_kachick/issues/180

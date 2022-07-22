#!/bin/bash

set -eux

brew_install() {
  which brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Needed to add the brew path...?

  brew install git coreutils tig tree curl wget \
    zsh sheldon \
    asdf openssl@1.1 ruby-install \
    jq gh ripgrep sqlite postgresql imagemagick pngquant

  brew install chruby --HEAD

  # Might need some setup after brew install
}

required_asdf_plugins() {
  # java is needed in early stage when I added scala, kotlin, clojure

  cat <<EOD
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
asdf_ommited_install() {
  missing_asdf_plugins | while read -r plugin; do
    asdf plugin add "$plugin"

    if [ "$plugin" != 'java' ]; then
      asdf install "$plugin" latest
    fi

    # asdf global is needless except java. Because .tool-versions is managed in same repository.
  done

  # https://github.com/halcyon/asdf-java/tree/master/data
  asdf install java adoptopenjdk-16.0.2+7
  asdf global java adoptopenjdk-16.0.2+7
}

brew_install
asdf_ommited_install

# When faced an OpenSSL issue, look at https://github.com/kachick/times_kachick/issues/180
# e.g: ruby-install ruby 3.1.2 -- --with-openssl-dir=$(brew --prefix openssl@3)
ls ~/.rubies/ruby-3.1.2 || ruby-install ruby-3.1.2

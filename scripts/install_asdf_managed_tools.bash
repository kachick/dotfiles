#!/usr/bin/env bash

set -euxo pipefail

# When faced ruby with OpenSSL issues, look at https://github.com/kachick/times_kachick/issues/180
RUBY_CONFIGURE_OPTS=--with-openssl-dir="$(brew --prefix openssl@3)" asdf install ruby latest
# RUBY_CONFIGURE_OPTS=--with-openssl-dir="$(brew --prefix openssl@1.1)" asdf install ruby 3.0.4
# RUBY_CONFIGURE_OPTS=--with-openssl-dir="$(brew --prefix openssl@1.1)" asdf install ruby 2.7.6

asdf install

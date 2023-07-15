#!/usr/bin/env bash

set -euxo pipefail

register_login_shells() {
  local -r zsh_path="$(which zsh)"
  local -r fish_path="$(which fish)"
  local -r nushell_path="$(which nu)"

  # https://stackoverflow.com/a/3557165/1212807
  # https://stackoverflow.com/a/49049781/1212807
  (
    grep -qxF "$zsh_path" /etc/shells || echo "$zsh_path"
    grep -qxF "$fish_path" /etc/shells || echo "$fish_path"
    grep -qxF "$nushell_path" /etc/shells || echo "$nushell_path"
  ) | sudo tee -a /etc/shells
}

register_login_shells

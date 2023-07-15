#!/usr/bin/env bash

alias la='exa --long --all --group-directories-first'

alias zj='zellij attach "$(basename "$PWD")" || zellij --session "$(basename "$PWD")"'

# If you want line numbers in the side-by-side, consider to use delta
alias betterdiff='diff --side-by-side --color'

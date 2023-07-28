#!/usr/bin/env bash

alias la='exa --long --all --group-directories-first'

alias zj='zellij attach "$(basename "$PWD")" || zellij --session "$(basename "$PWD")"'

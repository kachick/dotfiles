#!/usr/bin/env bash

alias git-switch-default='git checkout main 2>/dev/null || git checkout master 2>/dev/null'
alias git-remote-upsteram="git remote | grep -E '^upstream$'|| git remote | grep -E '^origin$'"
# https://github.com/kyanny/git-delete-merged-branches/pull/6
alias git-delete-merged-branches="git branch --merged | grep -vE '((^\*)|^ *(main|master)$)' | xargs -I % git branch -d %"
alias git-cleanup-branches='git-switch-default && git pull $(git-remote-upsteram) $(git-current-branch) && git fetch $(git-remote-upsteram) --tags --prune && git-delete-merged-branches'

alias la='exa --long --all --group-directories-first'

alias zj='zellij attach "$(basename "$PWD")" || zellij --session "$(basename "$PWD")"'

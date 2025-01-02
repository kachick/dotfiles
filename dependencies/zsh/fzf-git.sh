# The MIT License (MIT)
#
# Copyright (c) 2024 Junegunn Choi
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# shellcheck disable=SC2039
[[ $0 = - ]] && return

if [[ $# -eq 1 ]]; then
  branches() {
    /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git branch "$@" --sort=-committerdate --sort=-HEAD --format=$'%(HEAD) %(color:yellow)%(refname:short) %(color:green)(%(committerdate:relative))\t%(color:blue)%(subject)%(color:reset)' --color=always | /nix/store/ndqpb82si5a7znlb4wa84sjncl4mvgqm-util-linux-2.39.4-bin/bin/column -ts$'\t'
  }
  refs() {
    /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git for-each-ref --sort=-creatordate --sort=-HEAD --color=always --format=$'%(refname) %(color:green)(%(creatordate:relative))\t%(color:blue)%(subject)%(color:reset)' |
      eval "$1" |
      /nix/store/vmby25zqxnx94awvj0k7zn0rsd0zyrwg-gnused-4.9/bin/sed 's#^refs/remotes/#\x1b[95mremote-branch\t\x1b[33m#; s#^refs/heads/#\x1b[92mbranch\t\x1b[33m#; s#^refs/tags/#\x1b[96mtag\t\x1b[33m#; s#refs/stash#\x1b[91mstash\t\x1b[33mrefs/stash#' |
      /nix/store/ndqpb82si5a7znlb4wa84sjncl4mvgqm-util-linux-2.39.4-bin/bin/column -ts$'\t'
  }
  case "$1" in
    branches)
      echo $'CTRL-O (open in browser) ╱ ALT-A (show all branches)\n'
      branches
      ;;
    all-branches)
      echo $'CTRL-O (open in browser)\n'
      branches -a
      ;;
    refs)
      echo $'CTRL-O (open in browser) ╱ ALT-E (examine in editor) ╱ ALT-A (show all refs)\n'
      refs '/nix/store/85amyk92rg19l4fy0qmy7wr4jmq8p5z0-gnugrep-3.11/bin/grep -v ^refs/remotes'
      ;;
    all-refs)
      echo $'CTRL-O (open in browser) ╱ ALT-E (examine in editor)\n'
      refs '/nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin/cat'
      ;;
    nobeep) ;;
    *) exit 1 ;;
  esac
elif [[ $# -gt 1 ]]; then
  set -e

  branch=$(/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git rev-parse --abbrev-ref HEAD 2> /dev/null)
  if [[ $branch = HEAD ]]; then
    branch=$(/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git describe --exact-match --tags 2> /dev/null || /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git rev-parse --short HEAD)
  fi

  # Only supports GitHub for now
  case "$1" in
    commit)
      hash=$(/nix/store/85amyk92rg19l4fy0qmy7wr4jmq8p5z0-gnugrep-3.11/bin/grep -o "[a-f0-9]\{7,\}" <<< "$2")
      path=/commit/$hash
      ;;
    branch|remote-branch)
      branch=$(/nix/store/vmby25zqxnx94awvj0k7zn0rsd0zyrwg-gnused-4.9/bin/sed 's/^[* ]*//' <<< "$2" | /nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin/cut -d' ' -f1)
      remote=$(/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git config branch."${branch}".remote || echo 'origin')
      branch=${branch#$remote/}
      path=/tree/$branch
      ;;
    remote)
      remote=$2
      path=/tree/$branch
      ;;
    file) path=/blob/$branch/$(/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git rev-parse --show-prefix)$2 ;;
    tag)  path=/releases/tag/$2 ;;
    *)    exit 1 ;;
  esac

  remote=${remote:-$(/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git config branch."${branch}".remote || echo 'origin')}
  remote_url=$(/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git remote get-url "$remote" 2> /dev/null || echo "$remote")

  if [[ $remote_url =~ ^git@ ]]; then
    url=${remote_url%.git}
    url=${url#git@}
    url=https://${url/://}
  elif [[ $remote_url =~ ^http ]]; then
    url=${remote_url%.git}
  fi

  case "$(uname -s)" in
    Darwin) open "$url$path"     ;;
    *)      /nix/store/9v7x5vabddvggsmy4gyim551gww2hsan-xdg-utils-1.2.1/bin/xdg-open "$url$path" ;;
  esac
  exit 0
fi

if [[ $- =~ i ]]; then
# -----------------------------------------------------------------------------

# Redefine this function to change the options
_fzf_git_fzf() {
  /nix/store/1jyfj7687609l2hjvjj3gs1c29ywbdn7-fzf-0.56.2/bin/fzf-tmux -p80%,60% -- \
    --layout=reverse --multi --height=50% --min-height=20 --border \
    --border-label-pos=2 \
    --color='header:italic:underline,label:blue' \
    --preview-window='right,50%,border-left' \
    --bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' "$@"
}

_fzf_git_check() {
  /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git rev-parse HEAD > /dev/null 2>&1 && return

  [[ -n $TMUX ]] && /nix/store/d8hzzxpnn22h6081a95r4889bc4zpb0y-tmux-3.5a/bin/tmux display-message "Not in a git repository"
  return 1
}

__fzf_git=/nix/store/6v7lm2ngvfjsdxc0f0ph8i97jjzj66gl-fzf-git-sh-0-unstable-2024-03-17/share/fzf-git-sh/fzf-git.sh

if [[ -z $_fzf_git_cat ]]; then
  # Sometimes /nix/store/28gvmy0w40b0dslxzmvqb6d4pigjjc4v-bat-0.24.0/bin/bat is installed as batcat
  export _fzf_git_cat="/nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin/cat"
  _fzf_git_bat_options="--style='${BAT_STYLE:-full}' --color=always --pager=never"
  if command -v batcat > /dev/null; then
    _fzf_git_cat="batcat $_fzf_git_bat_options"
  elif command -v /nix/store/28gvmy0w40b0dslxzmvqb6d4pigjjc4v-bat-0.24.0/bin/bat > /dev/null; then
    _fzf_git_cat="/nix/store/28gvmy0w40b0dslxzmvqb6d4pigjjc4v-bat-0.24.0/bin/bat $_fzf_git_bat_options"
  fi
fi

_fzf_git_files() {
  _fzf_git_check || return
  (/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git -c color.status=always status --short --no-branch
   /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git ls-files | /nix/store/85amyk92rg19l4fy0qmy7wr4jmq8p5z0-gnugrep-3.11/bin/grep -vxFf <(/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git status -s | grep '^[^?]' | /nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin/cut -c4-; echo :) | /nix/store/vmby25zqxnx94awvj0k7zn0rsd0zyrwg-gnused-4.9/bin/sed 's/^/   /') |
  _fzf_git_fzf -m --ansi --nth 2..,.. \
    --border-label '📁 Files' \
    --header $'CTRL-O (open in browser) ╱ ALT-E (open in editor)\n\n' \
    --bind "ctrl-o:execute-silent:/nix/store/p6k7xp1lsfmbdd731mlglrdj2d66mr82-bash-5.2p37/bin/bash $__fzf_git file {-1}" \
    --bind "alt-e:execute:${EDITOR:-vim} {-1} > /dev/tty" \
    --preview "/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git diff --no-ext-diff --color=always -- {-1} | /nix/store/vmby25zqxnx94awvj0k7zn0rsd0zyrwg-gnused-4.9/bin/sed 1,4d; $_fzf_git_cat {-1}" "$@" |
  /nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin/cut -c4- | /nix/store/vmby25zqxnx94awvj0k7zn0rsd0zyrwg-gnused-4.9/bin/sed 's/.* -> //'
}

_fzf_git_branches() {
  _fzf_git_check || return
  /nix/store/p6k7xp1lsfmbdd731mlglrdj2d66mr82-bash-5.2p37/bin/bash "$__fzf_git" branches |
  _fzf_git_fzf --ansi \
    --border-label '🌲 Branches' \
    --header-lines 2 \
    --tiebreak begin \
    --preview-window down,border-top,40% \
    --color hl:underline,hl+:underline \
    --no-hscroll \
    --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
    --bind "ctrl-o:execute-silent:/nix/store/p6k7xp1lsfmbdd731mlglrdj2d66mr82-bash-5.2p37/bin/bash $__fzf_git branch {}" \
    --bind "alt-a:change-border-label(🌳 All branches)+reload:/nix/store/p6k7xp1lsfmbdd731mlglrdj2d66mr82-bash-5.2p37/bin/bash \"$__fzf_git\" all-branches" \
    --preview '/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $(/nix/store/vmby25zqxnx94awvj0k7zn0rsd0zyrwg-gnused-4.9/bin/sed s/^..// <<< {} | /nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin/cut -d" " -f1) --' "$@" |
  /nix/store/vmby25zqxnx94awvj0k7zn0rsd0zyrwg-gnused-4.9/bin/sed 's/^..//' | /nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin/cut -d' ' -f1
}

_fzf_git_tags() {
  _fzf_git_check || return
  /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git tag --sort -version:refname |
  _fzf_git_fzf --preview-window right,70% \
    --border-label '📛 Tags' \
    --header $'CTRL-O (open in browser)\n\n' \
    --bind "ctrl-o:execute-silent:/nix/store/p6k7xp1lsfmbdd731mlglrdj2d66mr82-bash-5.2p37/bin/bash $__fzf_git tag {}" \
    --preview '/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git show --color=always {}' "$@"
}

_fzf_git_hashes() {
  _fzf_git_check || return
  /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  _fzf_git_fzf --ansi --no-sort --bind 'ctrl-s:toggle-sort' \
    --border-label '🍡 Hashes' \
    --header $'CTRL-O (open in browser) ╱ CTRL-D (diff) ╱ CTRL-S (toggle sort)\n\n' \
    --bind "ctrl-o:execute-silent:/nix/store/p6k7xp1lsfmbdd731mlglrdj2d66mr82-bash-5.2p37/bin/bash $__fzf_git commit {}" \
    --bind 'ctrl-d:execute:/nix/store/85amyk92rg19l4fy0qmy7wr4jmq8p5z0-gnugrep-3.11/bin/grep -o "[a-f0-9]\{7,\}" <<< {} | /nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin/head -n 1 | /nix/store/w8pnfazxqwmrqmwkb5zrz1bifsd8abxl-findutils-4.10.0/bin/xargs /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git diff > /dev/tty' \
    --color hl:underline,hl+:underline \
    --preview '/nix/store/85amyk92rg19l4fy0qmy7wr4jmq8p5z0-gnugrep-3.11/bin/grep -o "[a-f0-9]\{7,\}" <<< {} | /nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin/head -n 1 | /nix/store/w8pnfazxqwmrqmwkb5zrz1bifsd8abxl-findutils-4.10.0/bin/xargs /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git show --color=always' "$@" |
  /nix/store/nnin69nrnrrmnv2scbwyfkgh1rf51gh1-gawk-5.3.1/bin/awk 'match($0, /[a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]*/) { print substr($0, RSTART, RLENGTH) }'
}

_fzf_git_remotes() {
  _fzf_git_check || return
  /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git remote -v | /nix/store/nnin69nrnrrmnv2scbwyfkgh1rf51gh1-gawk-5.3.1/bin/awk '{print $1 "\t" $2}' | /nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin/uniq |
  _fzf_git_fzf --tac \
    --border-label '📡 Remotes' \
    --header $'CTRL-O (open in browser)\n\n' \
    --bind "ctrl-o:execute-silent:/nix/store/p6k7xp1lsfmbdd731mlglrdj2d66mr82-bash-5.2p37/bin/bash $__fzf_git remote {1}" \
    --preview-window right,70% \
    --preview '/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {1}/"$(/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git rev-parse --abbrev-ref HEAD)" --' "$@" |
  /nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin/cut -d$'\t' -f1
}

_fzf_git_stashes() {
  _fzf_git_check || return
  /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git stash list | _fzf_git_fzf \
    --border-label '🥡 Stashes' \
    --header $'CTRL-X (drop stash)\n\n' \
    --bind 'ctrl-x:reload(/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git stash drop -q {1}; /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git stash list)' \
    -d: --preview '/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git show --color=always {1}' "$@" |
  /nix/store/b1wvkjx96i3s7wblz38ya0zr8i93zbc5-coreutils-9.5/bin/cut -d: -f1
}

_fzf_git_lreflogs() {
  _fzf_git_check || return
  /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git reflog --color=always --format="%C(blue)%gD %C(yellow)%h%C(auto)%d %gs" | _fzf_git_fzf --ansi \
    --border-label '📒 Reflogs' \
    --preview '/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git show --color=always {1}' "$@" |
  /nix/store/nnin69nrnrrmnv2scbwyfkgh1rf51gh1-gawk-5.3.1/bin/awk '{print $1}'
}

_fzf_git_each_ref() {
  _fzf_git_check || return
  /nix/store/p6k7xp1lsfmbdd731mlglrdj2d66mr82-bash-5.2p37/bin/bash "$__fzf_git" refs | _fzf_git_fzf --ansi \
    --nth 2,2.. \
    --tiebreak begin \
    --border-label '☘️  Each ref' \
    --header-lines 2 \
    --preview-window down,border-top,40% \
    --color hl:underline,hl+:underline \
    --no-hscroll \
    --bind 'ctrl-/:change-preview-window(down,70%|hidden|)' \
    --bind "ctrl-o:execute-silent:/nix/store/p6k7xp1lsfmbdd731mlglrdj2d66mr82-bash-5.2p37/bin/bash $__fzf_git {1} {2}" \
    --bind "alt-e:execute:${EDITOR:-vim} <(/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git show {2}) > /dev/tty" \
    --bind "alt-a:change-border-label(🍀 Every ref)+reload:/nix/store/p6k7xp1lsfmbdd731mlglrdj2d66mr82-bash-5.2p37/bin/bash \"$__fzf_git\" all-refs" \
    --preview '/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {2} --' "$@" |
  /nix/store/nnin69nrnrrmnv2scbwyfkgh1rf51gh1-gawk-5.3.1/bin/awk '{print $2}'
}

_fzf_git_worktrees() {
  _fzf_git_check || return
  /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git worktree list | _fzf_git_fzf \
    --border-label '🌴 Worktrees' \
    --header $'CTRL-X (remove worktree)\n\n' \
    --bind 'ctrl-x:reload(/nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git worktree remove {1} > /dev/null; /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git worktree list)' \
    --preview '
      /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git -c color.status=always -C {1} status --short --branch
      echo
      /nix/store/1zgzrsbq3b0f06k76pha0r8hmfwvjvc0-git-2.47.0/bin/git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" {2} --
    ' "$@" |
  /nix/store/nnin69nrnrrmnv2scbwyfkgh1rf51gh1-gawk-5.3.1/bin/awk '{print $1}'
}

if [[ -n "${BASH_VERSION:-}" ]]; then
  __fzf_git_init() {
    bind '"\er": redraw-current-line'
    local o
    for o in "$@"; do
      bind '"\C-g\C-'${o:0:1}'": "`_fzf_git_'$o'`\e\C-e\er"'
      bind '"\C-g'${o:0:1}'": "`_fzf_git_'$o'`\e\C-e\er"'
    done
  }
elif [[ -n "${ZSH_VERSION:-}" ]]; then
  __fzf_git_join() {
    local item
    while read item; do
      echo -n "${(q)item} "
    done
  }

  __fzf_git_init() {
    local m o
    for o in "$@"; do
      eval "fzf-git-$o-widget() { local result=\$(_fzf_git_$o | __fzf_git_join); zle reset-prompt; LBUFFER+=\$result }"
      eval "zle -N fzf-git-$o-widget"
      for m in emacs vicmd viins; do
        eval "bindkey -M $m '^g^${o[1]}' fzf-git-$o-widget"
        eval "bindkey -M $m '^g${o[1]}' fzf-git-$o-widget"
      done
    done
  }
fi
__fzf_git_init files branches tags remotes hashes stashes lreflogs each_ref worktrees

# -----------------------------------------------------------------------------
fi

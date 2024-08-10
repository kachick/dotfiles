parser_definition() {
  setup REST help:usage -- "Usage: walk [options]... [arguments]..." ''
  msg -- 'Options:'
  # Don't use $PWD to avoid printing needless absolute path for current directory
  option WALK_FROM -d --working-directory on:"/tmp" -- "Working Directory"
  disp :usage --help
}

eval "$(getoptions parser_definition) exit 1"

# if [ $# -ge 1 ]; then
#   query="$1"
# else
#   query=""
# fi

# shellcheck disable=SC2016
fd --type f --hidden --follow --exclude .git . "$WALK_FROM" |
  fzf --query "$@" --preview 'bat --color=always {}' --preview-window '~3' --bind 'enter:become(command "$EDITOR" {})'

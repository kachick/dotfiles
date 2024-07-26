working_directory='.' # Don't use $PWD to avoid printing needless absolute path for current directory

if [ $# -ge 1 ]; then
	working_directory="$1"
fi

if [ $# -ge 2 ]; then
	query="$2"
else
	query=""
fi

# shellcheck disable=SC2016
fd --type f --hidden --follow --exclude .git . "$working_directory" |
	fzf --query "$query" --preview 'bat --color=always {}' --preview-window '~3' --bind 'enter:become(command "$EDITOR" {})'

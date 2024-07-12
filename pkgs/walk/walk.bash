if [ $# -ge 1 ]; then
	query="$1"
else
	query=""
fi

# shellcheck disable=SC2016
fzf --query "$query" --preview 'bat --color=always {}' --preview-window '~3' --bind 'enter:become(command "$EDITOR" {})'

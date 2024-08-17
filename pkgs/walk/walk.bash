if [ $# -ge 1 ]; then
	query="$1"
	shift
else
	query=""
fi

# Don't use $PWD to avoid printing needless absolute path for current directory
# So use '.' or fd command defaults

# shellcheck disable=SC2016
fd --type f --hidden --follow --exclude .git . "$@" |
	fzf --query "$query" --preview 'bat --color=always {}' --preview-window '~3' --bind 'enter:become(command "$EDITOR" {})'

parser_definition() {
	setup REST help:usage -- "Usage: walk [options]... [fuzzy queries]..." ''
	msg -- 'Options:'
	# Don't use $PWD to avoid printing needless absolute path for current directory
	option working_directory -d --working_directory on:"." -- "working directory"
	disp :usage --help
}

eval "$(getoptions parser_definition) exit 1"

if [ $# -ge 1 ]; then
	query="$1"
else
	query=""
fi

# shellcheck disable=SC2016,SC2154
fd --type f --hidden --follow --exclude .git . "$working_directory" |
	fzf --query "$query" --preview 'bat --color=always {}' --preview-window '~3' --bind 'enter:become(command "$EDITOR" {})'

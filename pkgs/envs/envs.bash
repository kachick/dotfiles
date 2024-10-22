if [ $# -ge 1 ]; then
	query="$1"
	shift
else
	query=""
fi

env | sort | fzf --delimiter '=' --nth '1' --query "$query"

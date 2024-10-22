if [ $# -ge 1 ]; then
	query="$1"
	shift
else
	query=""
fi

summarize() {
	local -r env_name="$1"
	local -r val="$env_name"
	printf "%s=%.25s...\n" "$env_name" "$(echo "$val" | tr '\n' ' ')"
}

# shellcheck disable=SC2016
compgen -v | sort | xargs --no-run-if-empty --max-lines=1 bash -c summarize | fzf --delimiter '=' --nth '1' --query "$query"

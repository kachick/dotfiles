if [ $# -ge 1 ]; then
	query="$1"
	shift
else
	query=""
fi

# summarize() {
# 	local -r env_name="$1"
# 	local -r val="$env_name"
# 	printf "%s=%.25s...\n" "$env_name" "$(echo "$val" | tr '\n' ' ')"
# }

ruby -w "$RUBY_SCRIPT_PATH" | fzf --delimiter '=' --nth '1' --query "$query"

if [ $# -lt 2 ]; then
	# shellcheck disable=SC2016
	echo 'Should be specified $1:<PATTERN> and $2:[REPLACE]' >&2
fi

# https://stackoverflow.com/a/28090709
nl=$'\n'

fzf_options="$(
	cat <<-EOF
		--style full --height 80% --layout reverse \
		--border --padding '1,2' --border-label ' Inline Replacer ' \
		--input-label ' Path Filter ' \
		--header-label ' Keybinds ' \
		--header "Tab(+Shift): Toggle${nl}Alt+t: Toggle All" \
		--bind 'alt-t:toggle-all'
	EOF
)"

fd --type file --hidden --exclude .git --exclude .direnv --exclude node_modules |
	sad --fzf="$fzf_options" "$@"

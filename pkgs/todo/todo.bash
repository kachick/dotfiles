if [ $# -ge 1 ]; then
	query="$1"
else
	query=''
fi

# open bat with line number in preview: https://github.com/sharkdp/bat/issues/1185#issuecomment-1301473901
# shellcheck disable=SC2016
git grep --perl-regexp --line-number --column --color=always '\b(?<=TODO|FIXME|BUG)\b\S+' |
	fzf --ansi --delimiter : --nth 4.. --query "$query" \
		--preview 'bat {1} --color=always --highlight-line={2}' --preview-window='~3,+{2}+3/4' \
		--bind 'enter:become(command "$EDITOR" {1}:{2}:{3})'

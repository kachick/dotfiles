# open bat with line number in preview: https://github.com/sharkdp/bat/issues/1185#issuecomment-1301473901
git grep --perl-regexp --line-number --column --color=always '\b(?<=TODO|FIXME|BUG)\b\S+' |
	fzf --ansi --delimiter : --nth 4.. \
		--preview 'bat {1} --color=always --highlight-line={2}' --preview-window='~3,+{2}+3/4' \
		--bind 'enter:become(micro -parsecursor=true {1}:{2}:{3})'

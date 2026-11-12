if [ $# -ge 1 ]; then
	query="$1"
	shift
else
	query=""
fi

fzf_args=()
if [[ "$query" == " "* ]]; then
	fzf_args+=(--bind 'start:beginning-of-line')
fi

# Don't use $PWD to avoid printing needless absolute path for current directory
# So use '.' or fd command defaults

# shellcheck disable=SC2016
fd --type f --hidden --follow --exclude .git . "$@" |
	fzf --query "$query" "${fzf_args[@]}" \
		--with-shell 'bash -c' \
		--preview 'preview {}' \
		--preview-window '~3' \
		--bind 'enter:become(case {} in *.md|*.markdown) exec leaf {} ;; *) exec "$EDITOR" {} ;; esac)'

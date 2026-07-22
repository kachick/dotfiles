if [ $# -ge 1 ]; then
	query="$1"
else
	query=""
fi

# shellcheck disable=SC2016
ghq list | fzf --query "$query" --delimiter / --nth 3.. --preview \
	'eza --group-directories-first --icons=always --color=always --no-user --no-time --no-filesize --no-permissions --sort=modified "$(
          ghq list --full-path --exact {}
        )"' --preview-window '~3'

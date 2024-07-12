if [ $# -ge 1 ]; then
	query="$1"
else
	query=""
fi

# source nixpkgs file does not work here: source "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh"
# https://github.com/junegunn/fzf-git.sh/blob/0f1e52079ffd9741eec723f8fd92aa09f376602f/fzf-git.sh#L118C1-L125C2
_fzf_git_fzf() {
	local -r query="$1"

	fzf-tmux --query "$query" -p80%,60% -- \
		--layout=reverse --multi --height=85% --min-height=20 --border \
		--border-label-pos=2 \
		--color='header:italic:underline,label:blue' \
		--preview-window='right,50%,border-left' \
		--bind='ctrl-/:change-preview-window(down,50%,border-top|hidden|)' "$@"
}

# TODO: Replace enter:become with enter:execute. But didn't work for some ref as 2050a94
git-log-simple | _fzf_git_fzf --ansi --nth 1,3.. --no-sort --query "$query" --border-label '🪵 Logs' \
	--preview 'echo {} | \
          cut --delimiter " " --fields 2 --only-delimited | \
          ansi2txt | \
          xargs --no-run-if-empty --max-lines=1 git show --color=always | \
          bat --language=gitlog --color=always --style=plain --wrap=character' \
	--header $'CTRL-O (Open in browser) ╱ Enter (git show with bat)\n\n' \
	--bind 'ctrl-o:execute-silent(gh browse {2})' \
	--bind 'enter:become(git show --color=always {2} | bat --language=gitlog --color=always --style=plain --wrap=character)'

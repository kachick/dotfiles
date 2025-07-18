if [ $# -ge 1 ]; then
	query="$1"
else
	query=""
fi

# source nixpkgs file does not work here: source "${pkgs.fzf-git-sh}/share/fzf-git-sh/fzf-git.sh"
# https://github.com/junegunn/fzf-git.sh/blob/7e73ab608825fefa44e9965780dbbf96b10fe821/fzf-git.sh#L152-L165
_fzf_git_fzf() {
	local -r query="$1"

	fzf --query "$query" \
		--height 50% --tmux 90%,70% \
		--layout reverse --multi --min-height 20+ --border \
		--no-separator --header-border horizontal \
		--border-label-pos 2 \
		--color 'label:blue' \
		--preview-window 'right,50%' --preview-border line \
		--bind 'ctrl-/:change-preview-window(down,50%|hidden|)' "$@"
}

# TODO: Replace enter:become with enter:execute. But didn't work for some ref as 2050a94
git-log-simple | _fzf_git_fzf --ansi --nth 1,3.. --no-sort --query "$query" --border-label '🪵 Logs' \
	--preview 'echo {} | \
		cut --delimiter " " --fields 2 --only-delimited | \
		ansi2txt | \
		xargs --no-run-if-empty --max-lines=1 git show --color=always | \
		riff --color=on | \
		bat --language=gitlog --color=always --style=plain --wrap=character' \
	--header $'CTRL-O (Open in browser) / CTRL-R (Revert)\nEnter (Detail)\n\n' \
	--bind 'ctrl-o:execute-silent(gh browse {2})' \
	--bind 'ctrl-r:become(git revert {2})' \
	--bind 'enter:become(git show --color=always {2} | riff --color=on | bat --language=gitlog --color=always --style=plain --wrap=character)'

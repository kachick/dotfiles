# Don't use `gh --json --template`, golang template syntax cannot use if in pipe, so changing color for draft state will gone
# gh supports interactive checkout since version 2.67.0, however it is not enough for previewing feature

# shellcheck disable=SC2016
GH_FORCE_TTY='100%' gh pr list --state 'open' |
	fzf --ansi --header-lines=4 --nth 2.. \
		--preview 'GH_FORCE_TTY=$FZF_PREVIEW_COLUMNS gh pr view {1}' \
		--preview-window down \
		--header $'ALT-C (Checkout) / CTRL-O (Open in browser)\nCTRL-ALT-S (Squash and merge) ╱ CTRL-ALT-M (Merge)\n\n' \
		--bind 'alt-c:become(gh pr checkout {1})' \
		--bind 'ctrl-o:execute-silent(gh pr view {1} --web)' \
		--bind 'ctrl-alt-s:become(wait-and-squashmerge {1})' \
		--bind 'ctrl-alt-m:become(gh pr checks {1} --interval 5 --watch --fail-fast && gh pr merge {1} --delete-branch)' \
		--bind 'enter:become(echo {1} | tr -d "#")'

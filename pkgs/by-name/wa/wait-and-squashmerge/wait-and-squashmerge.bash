readonly pr_number="$1"
commit_subject="$(gh pr view "$pr_number" --json title --template '{{ .title }}' | "$EDITOR")"
readonly commit_subject

gh pr checks "$pr_number" --interval 5 --watch --fail-fast &&
	gh pr merge "$pr_number" --delete-branch --squash --subject "$commit_subject"

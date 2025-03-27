# Providing env is an escape hatch
# `SKIP` is adjusted for pre-commit convention. See https://github.com/gitleaks/gitleaks/blob/v8.24.0/README.md?plain=1#L121-L127
# Copying to another env is avoiding -o error: https://stackoverflow.com/a/7832158
declare -A SKIP_HOOKS=([gitleaks]='false' [typos]='false')
while IFS=, read -r target; do
	[ -z "$target" ] && continue
	SKIP_HOOKS["$target"]='true'
done < <(echo "${SKIP:-}")

REMOTE_DEFAULT_BRANCH="$(git symbolic-ref 'refs/remotes/origin/HEAD')"

# list of arguments: https://git-scm.com/docs/githooks#_pre_push
while read -r local_ref _local_oid remote_ref _remote_oid; do
	if [[ "${SKIP_HOOKS[gitleaks]}" != 'true' ]]; then
		# TODO: Might be better to skip if author is another person in nixpkgs
		gitleaks --verbose git --log-opts="$REMOTE_DEFAULT_BRANCH..$local_ref"
	fi

	if [[ "${SKIP_HOOKS[typos]}" != 'true' ]]; then
		git log --patch "$REMOTE_DEFAULT_BRANCH..$local_ref" | typos --config "$TYPOS_CONFIG_PATH" -

		# Git ref is not a file path, but avoiding a typos limitation for slash
		# See https://github.com/crate-ci/typos/issues/758 for detail
		basename "$remote_ref" | typos --config "$TYPOS_CONFIG_PATH" -
	fi
done

run_local_hook 'pre-push' "$@"

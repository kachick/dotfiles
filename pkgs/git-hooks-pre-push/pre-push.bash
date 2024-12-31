# list of arguments: https://git-scm.com/docs/githooks#_pre_push
while read -r local_ref _local_oid remote_ref _remote_oid; do
	# - trufflehog pre-commit hook having crucial limitations. https://github.com/trufflesecurity/trufflehog/blob/v3.88.0/README.md?plain=1#L628-L629
	# - Adding `--since-commit main` made 10x slower... :<
	trufflehog git "file://${PWD}" --results='verified,unknown' --branch "$local_ref" --fail

	# Git ref is not a file path, but avoiding a typos bug for slash
	# https://github.com/crate-ci/typos/issues/758
	basename "$remote_ref" | typos --config "$TYPOS_CONFIG_PATH" -
done

run_local_hook 'pre-push' "$@"

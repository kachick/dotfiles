# Avoiding -o error: https://stackoverflow.com/a/7832158
# This is an escape hatch for large repository
DO_HOOK=${RUN_GITHOOK_HOG:-true}

# list of arguments: https://git-scm.com/docs/githooks#_pre_push
while read -r local_ref _local_oid remote_ref _remote_oid; do
	# - trufflehog pre-commit hook having crucial limitations. https://github.com/trufflesecurity/trufflehog/blob/v3.88.0/README.md?plain=1#L628-L629
	# - Adding `--since-commit main` made 10x slower... :<
	if [[ "$DO_HOOK" != "false" ]]; then
		trufflehog git "file://${PWD}" --results='verified,unknown' --branch "$local_ref" --fail
	fi

	# Git ref is not a file path, but avoiding a typos bug for slash
	# https://github.com/crate-ci/typos/issues/758
	basename "$remote_ref" | typos --config "$TYPOS_CONFIG_PATH" -
done

run_local_hook 'pre-push' "$@"

# list of arguments: https://git-scm.com/docs/githooks#_pre_push
while read -r _local_ref _local_oid remote_ref _remote_oid; do
	# Git ref is not a file path, but avoiding a typos bug for slash
	# https://github.com/crate-ci/typos/issues/758
	basename "$remote_ref" | typos --config "$TYPOS_CONFIG_PATH" -
done

run_local_hook 'pre-push' "$@"

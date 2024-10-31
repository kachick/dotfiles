typos --config "$TYPOS_CONFIG_PATH" "$1"

run_local_hook 'commit-msg' "$@"

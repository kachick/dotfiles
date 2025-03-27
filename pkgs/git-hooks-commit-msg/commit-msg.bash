typos --config "$TYPOS_CONFIG_PATH" "$1"
gitleaks --verbose stdin <"$1"

run_local_hook 'commit-msg' "$@"

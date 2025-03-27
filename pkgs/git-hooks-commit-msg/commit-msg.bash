declare -A SKIP_HOOKS=([gitleaks]='false' [typos]='false')
while IFS=, read -r target; do
	[ -z "$target" ] && continue
	SKIP_HOOKS["$target"]='true'
done < <(echo "${SKIP:-}")

if [[ "${SKIP_HOOKS[typos]}" != 'true' ]]; then
	typos --config "$TYPOS_CONFIG_PATH" "$1"
fi

if [[ "${SKIP_HOOKS[gitleaks]}" != 'true' ]]; then
	gitleaks --verbose stdin <"$1"
fi

run_local_hook 'commit-msg' "$@"

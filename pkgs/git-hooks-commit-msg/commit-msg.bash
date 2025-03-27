declare -A want=([gitleaks]='true' [typos]='true')
while IFS=, read -r tool; do
	[ -z "$tool" ] && continue
	want["$tool"]='false'
done < <(echo "${SKIP:-}")

if [[ "${want[typos]}" == 'true' ]]; then
	typos --config "$TYPOS_CONFIG_PATH" "$1"
fi

if [[ "${want[gitleaks]}" == 'true' ]]; then
	gitleaks --verbose stdin <"$1"
fi

run_local_hook 'commit-msg' "$@"

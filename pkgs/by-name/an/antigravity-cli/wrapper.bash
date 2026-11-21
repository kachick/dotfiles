# Inject read-only sandbox access for the shared .git directory in linked worktrees
# so read-only git commands keep working inside the sandbox without BypassSandbox.
script_path="$(readlink -f -- "${BASH_SOURCE[0]}")"
agy_bin="$(dirname -- "$script_path")/.agy-wrapped"

skip_inject=0
expect_value=0
seen_positional=0

for arg in "$@"; do
	if [[ "$expect_value" -eq 1 ]]; then
		expect_value=0
		continue
	fi

	case "$arg" in
	--settings | --settings=* | -h | --help | -v | --version)
		skip_inject=1
		break
		;;
	--add-dir | --agent | --conversation | --effort | --input-format | --json-schema | --log-file | --mode | --model | --output-format | --print-timeout | --project | --prompt | -p | --prompt-interactive | -i)
		expect_value=1
		;;
	--)
		break
		;;
	-*) ;;
	*)
		if [[ "$seen_positional" -eq 0 ]]; then
			seen_positional=1
			case "$arg" in
			acp | agent | agents | changelog | help | install | mcp | mic-serve | models | plugin | plugins | remote-control | update)
				skip_inject=1
				break
				;;
			esac
		fi
		;;
	esac
done

if [[ "$skip_inject" -eq 0 ]]; then
	if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null || true)" == "true" ]]; then
		git_dir="$(git rev-parse --path-format=absolute --git-dir 2>/dev/null || true)"
		common_dir="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
		settings_file="${HOME}/.gemini/antigravity-cli/settings.json"

		if [[ -n "$git_dir" && -n "$common_dir" && "$git_dir" != "$common_dir" && "$common_dir" == /* && -d "$common_dir" && -r "$settings_file" ]]; then
			if merged_settings="$(jq -ce --arg rule "read_file(${common_dir})" '{permissions: ((.permissions // {}) | .allow = (((.allow // []) + [$rule]) | unique))}' "$settings_file" 2>/dev/null)"; then
				exec "$agy_bin" --settings "$merged_settings" "$@"
			fi
		fi
	fi
fi

exec "$agy_bin" "$@"

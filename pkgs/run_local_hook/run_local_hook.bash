# You should remove local hooks as `git config --local --unset core.hooksPath` to prefer global hooks for the entry point

readonly hook_name="$1"
shift

# Make sure which hook has been run. Some hooks might be executed together and it will be hard to debug
echo "$hook_name"

repository_path="$(git rev-parse --show-toplevel)"
readonly repository_path

# Avoiding -o error only at here: https://stackoverflow.com/a/7832158
TRUST_PATH=${GIT_HOOKS_TRUST_REPOS:-}

if [[ -x "${repository_path}/.git/hooks/${hook_name}" ]]; then
	# Why using `case`: https://unix.stackexchange.com/a/32054
	case ":$TRUST_PATH:" in
	*:$repository_path:*)
		"${repository_path}/.git/hooks/${hook_name}" "$@"
		;;
	*)
		cat <<'EOF'
Found an ignored local hook.
You can allow it as

```bash
export GIT_HOOKS_TRUST_REPOS="${GIT_HOOKS_TRUST_REPOS}:${PWD}"
```
EOF
		;;
	esac
fi

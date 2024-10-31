# You should remove local hooks as `git config --local --unset core.hooksPath` to prefer global hooks for the entry point

readonly hook_name="$1"
shift

repository_path="$(git rev-parse --show-toplevel)"
readonly repository_path

if [[ -x "${repository_path}/.git/hooks/${hook_name}" ]]; then
	# Why using `case`: https://unix.stackexchange.com/a/32054
	case ":$GIT_HOOKS_TRUST_REPOS:" in
	*:$repository_path:*)
		exec "${repository_path}/.git/hooks/${hook_name}" "$@"
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

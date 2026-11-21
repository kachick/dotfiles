# Work around eza --git-ignore limitations (libgit2):
# - Passing a git-ignored directory (e.g., `lat ./dist` or `lat ./.rumdl_cache`)
#   prints only the directory line and hides all children inside it.
# - Passing `./dir` with a leading `./` can fail to match nested ignore rules.
# - eza has no flag to unset an earlier `--git-ignore` (https://github.com/eza-community/eza/issues/1875).
# Also hide `.git` via `--ignore-glob=.git` because `la` passes `--all`.

is_git_working_dir_not_ignored() {
	local dir="$1"
	[ -d "$dir" ] || return 1

	if git check-ignore --quiet -- "$dir" 2>/dev/null; then
		return 1
	fi

	# git check-ignore exits with:
	#   0: path is ignored (including `<dir>/.gitignore` with `*`)
	#   1: path is not ignored (and inside a git work tree)
	# 128: not a git repository, or inside `.git/`
	local status=0
	git -C "$dir" check-ignore --quiet . 2>/dev/null || status=$?
	[ "$status" -eq 1 ]
}

use_git_ignore=true
ignore_git_dir=true
has_path_arg=false
after_dash_dash=false
expect_opt_arg=false
args=()

for arg in "$@"; do
	if [ "$expect_opt_arg" = true ]; then
		expect_opt_arg=false
		args+=("$arg")
		continue
	fi

	if [ "$after_dash_dash" = false ]; then
		case "$arg" in
		--)
			after_dash_dash=true
			args+=("$arg")
			continue
			;;
		-L | --level | -I | --ignore-glob | -s | --sort | -t | --time | --time-style | --color | --colour | --icons | --hyperlink | -w | --width)
			expect_opt_arg=true
			args+=("$arg")
			continue
			;;
		-*)
			args+=("$arg")
			continue
			;;
		esac
	fi

	has_path_arg=true
	if [ -e "$arg" ]; then
		if ! is_git_working_dir_not_ignored "$arg"; then
			use_git_ignore=false
		fi

		clean_path="$arg"
		while [[ "$clean_path" == ./* && "${clean_path#./}" != -* ]]; do
			clean_path="${clean_path#./}"
		done
		clean_path="${clean_path:-.}"
		args+=("$clean_path")

		case "${clean_path%/}" in
		.git | */.git)
			ignore_git_dir=false
			;;
		esac
	else
		args+=("$arg")
	fi
done

if [ "$has_path_arg" = false ]; then
	if ! is_git_working_dir_not_ignored "."; then
		use_git_ignore=false
	fi
fi

opts=(--tree)
if [ "$ignore_git_dir" = true ]; then
	opts=(--ignore-glob=.git "${opts[@]}")
fi
if [ "$use_git_ignore" = true ]; then
	opts=(--git-ignore "${opts[@]}")
fi

la "${opts[@]}" "${args[@]}"

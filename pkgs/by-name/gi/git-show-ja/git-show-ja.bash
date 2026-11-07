rev=""
git_args=()
translate_all=0

for arg in "$@"; do
	case "$arg" in
	--all)
		translate_all=1
		;;
	-*)
		git_args+=("$arg")
		;;
	*)
		if [ -z "$rev" ]; then
			rev="$arg"
		fi
		git_args+=("$arg")
		;;
	esac
done

if [ -z "$rev" ]; then
	rev="HEAD"
fi

run_git_show() {
	if [ ${#git_args[@]} -gt 0 ]; then
		git show "${git_args[@]}"
	else
		git show
	fi
}

port="${PLAMO_PORT:-8080}"
server_url="http://127.0.0.1:${port}"
if ! curl --silent --fail --max-time 0.1 "${server_url}/health" >/dev/null 2>&1; then
	run_git_show
	exit 0
fi

if [ "$translate_all" -eq 1 ]; then
	msg="$(git log -1 --format='%B' "$rev" 2>/dev/null || true)"
	timeout_sec="5s"
else
	# Default: translate subject line only for sub-second preview in git lf
	msg="$(git log -1 --format='%s' "$rev" 2>/dev/null || true)"
	timeout_sec="2s"
fi

if [ -z "$msg" ]; then
	run_git_show
	exit 0
fi

trans="$(printf '%s' "$msg" | timeout "$timeout_sec" plamo-trans 2>/dev/null || true)"
if [ -z "$trans" ]; then
	run_git_show
	exit 0
fi

formatted_trans="$(printf '%s' "$trans" | awk '{ print "    \033[36m[訳] " $0 "\033[0m" }')"

if [ "$translate_all" -eq 1 ]; then
	# Inject full translation right before diff starts
	run_git_show | awk -v trans="$formatted_trans" '
	BEGIN { in_header = 1; inserted = 0; }
	in_header && /^$/ { in_header = 0; print; next; }
	!in_header && !inserted && /^(\033\[[0-9;]*m)?diff --git/ {
	  print trans "\n";
	  inserted = 1;
	}
	{ print }
	END {
	  if (!inserted) {
	    print "\n" trans;
	  }
	}
	'
else
	# Default: Inject subject translation directly under the first subject line
	run_git_show | awk -v trans="$formatted_trans" '
	BEGIN { in_header = 1; inserted = 0; }
	in_header && /^$/ { in_header = 0; print; next; }
	!in_header && !inserted && /^(\033\[[0-9;]*m)?    / {
	  print;
	  print trans;
	  inserted = 1;
	  next;
	}
	{ print }
	'
fi

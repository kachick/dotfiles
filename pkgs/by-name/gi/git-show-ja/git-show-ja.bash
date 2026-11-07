rev=""
git_args=()
for arg in "$@"; do
	case "$arg" in
	-*) ;;
	*)
		if [ -z "$rev" ]; then
			rev="$arg"
		fi
		;;
	esac
	git_args+=("$arg")
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

# Quick check if plamo service is alive (0.1s timeout).
# If unreachable or fails, pass through to raw git show immediately.
port="${PLAMO_PORT:-8080}"
server_url="http://127.0.0.1:${port}"
if ! curl --silent --fail --max-time 0.1 "${server_url}/health" >/dev/null 2>&1; then
	run_git_show
	exit 0
fi

# Extract commit message
msg="$(git log -1 --format='%B' "$rev" 2>/dev/null || true)"
if [ -z "$msg" ]; then
	run_git_show
	exit 0
fi

# Limit input length to ~500 chars to avoid latency on large commits, and set 1s timeout
trans="$(printf '%s' "$msg" | head -c 500 | timeout 1s plamo-trans 2>/dev/null || true)"
if [ -z "$trans" ]; then
	run_git_show
	exit 0
fi

# Format translated text with cyan color and indent
formatted_trans="$(printf '%s' "$trans" | awk '{ print "    \033[36m[訳] " $0 "\033[0m" }')"

# Stream git show output and inject translation right before diff starts
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

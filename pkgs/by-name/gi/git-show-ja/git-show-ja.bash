rev=""
git_args=()

for arg in "$@"; do
	case "$arg" in
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

port="${PLAMO_PORT:-8080}"
server_url="http://127.0.0.1:${port}"

# Fail-closed: Require llama-server to be active
if ! curl --silent --fail --max-time 1 "${server_url}/health" >/dev/null 2>&1; then
	echo "Error: llama-server is not reachable at ${server_url}." >&2
	echo "Start the service with: systemctl --user start llama-plamo (or 'plamo-start')" >&2
	exit 1
fi

# Extract full commit message (subject and body)
msg="$(git log -1 --format='%B' "$rev")"
if [ -z "$msg" ]; then
	echo "Error: Could not retrieve commit message for '${rev}'." >&2
	exit 1
fi

# Show progress indicator if connected to terminal
if [ -t 2 ]; then
	printf '\033[33mTranslating commit message with PLaMo-3...\033[0m\r' >&2
fi

# Translate full message with 60s timeout
if ! trans="$(printf '%s' "$msg" | timeout 60s plamo-trans 2>/dev/null)"; then
	if [ -t 2 ]; then
		printf '\033[2K\r' >&2
	fi
	echo "Error: Failed to translate commit message for '${rev}'." >&2
	exit 1
fi

if [ -t 2 ]; then
	printf '\033[2K\r' >&2
fi

if [ -z "$trans" ]; then
	echo "Error: Translation result was empty for '${rev}'." >&2
	exit 1
fi

run_git_show() {
	if [ ${#git_args[@]} -gt 0 ]; then
		git show --color=always "${git_args[@]}"
	else
		git show --color=always
	fi
}

# Stream git show output and inject translation right before diff starts
inject_translation() {
	run_git_show | awk -v trans="$trans" '
	BEGIN { in_header = 1; inserted = 0; }
	in_header && /^$/ { in_header = 0; print; next; }
	!in_header && !inserted && /^(\033\[[0-9;]*m)?diff --git/ {
	  print "\033[36m<ja>\033[0m";
	  print "\033[36m" trans "\033[0m";
	  print "\033[36m</ja>\033[0m\n";
	  inserted = 1;
	}
	{ print }
	END {
	  if (!inserted) {
	    print "\n\033[36m<ja>\033[0m";
	    print "\033[36m" trans "\033[0m";
	    print "\033[36m</ja>\033[0m";
	  }
	}
	'
}

if [ -t 1 ] && command -v riff >/dev/null 2>&1; then
	inject_translation | riff
else
	inject_translation
fi

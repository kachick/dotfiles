port="${PLAMO_PORT:-18080}"
target_lang="ja"
form="plain"

show_help() {
	cat <<'EOF'
Usage: plamo-trans [OPTIONS] [TEXT...]

Translate text using local PLaMo-3-Translate via llama-server.
Reads from arguments if provided, otherwise reads from standard input.

Options:
  -t, --to LANG       Target language code (default: ja)
  -f, --form FORM     Sentence form: plain or polite (default: plain)
  -p, --port PORT     Port of llama-server (default: 18080, env: PLAMO_PORT)
  -h, --help          Show this help message

Server controls:
  Start:   systemctl --user start llama-plamo (or plamo-start)
  Stop:    systemctl --user stop llama-plamo (or plamo-stop)
  Status:  systemctl --user status llama-plamo (or plamo-status)
EOF
}

args=()
while [ $# -gt 0 ]; do
	case "$1" in
	-h | --help)
		show_help
		exit 0
		;;
	-t | --to)
		target_lang="$2"
		shift 2
		;;
	-f | --form)
		form="$2"
		shift 2
		;;
	-p | --port)
		port="$2"
		shift 2
		;;
	--)
		shift
		while [ $# -gt 0 ]; do
			args+=("$1")
			shift
		done
		break
		;;
	-*)
		echo "Unknown option: $1" >&2
		show_help >&2
		exit 1
		;;
	*)
		args+=("$1")
		shift
		;;
	esac
done

if [ ${#args[@]} -gt 0 ]; then
	text="${args[*]}"
else
	if [ -t 0 ]; then
		echo "Error: No input text provided via arguments or stdin." >&2
		show_help >&2
		exit 1
	fi
	text="$(cat -)"
fi

trimmed="$(printf '%s' "$text" | tr -d '[:space:]')"
if [ -z "$trimmed" ]; then
	exit 0
fi

server_url="http://127.0.0.1:${port}"
if ! curl --silent --fail --max-time 2 "${server_url}/health" >/dev/null 2>&1; then
	echo "Error: llama-server is not reachable at ${server_url}." >&2
	if command -v systemctl >/dev/null 2>&1; then
		if systemctl --user is-failed llama-plamo >/dev/null 2>&1; then
			echo "Service 'llama-plamo' failed. Check logs with: journalctl --user -u llama-plamo -e" >&2
		elif [ "$(systemctl --user is-active llama-plamo 2>/dev/null)" = "activating" ]; then
			echo "Service 'llama-plamo' is still starting up. Please wait a moment." >&2
			echo "Monitor progress with: journalctl --user -u llama-plamo -f" >&2
		else
			echo "Start the service with: systemctl --user start llama-plamo (or 'plamo-start')" >&2
		fi
	else
		echo "Start the service with: systemctl --user start llama-plamo (or 'plamo-start')" >&2
	fi
	exit 1
fi

system_prompt="$(printf '[plamo-translate]\ntarget_lang=%s\nform=%s' "$target_lang" "$form")"

payload="$(jq -n \
	--arg sys "$system_prompt" \
	--arg usr "$text" \
	'{
    messages: [
      { role: "system", content: $sys },
      { role: "user", content: $usr }
    ],
    temperature: 0
  }')"

response="$(curl --silent --show-error --fail \
	--header "Content-Type: application/json" \
	--data "$payload" \
	"${server_url}/v1/chat/completions")"

result="$(printf '%s' "$response" | jq -r '.choices[0].message.content // empty')"

if [ -z "$result" ]; then
	echo "Error: Failed to extract translation from API response." >&2
	printf '%s\n' "$response" >&2
	exit 1
fi

printf '%s\n' "$result"

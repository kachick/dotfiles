# shellcheck shell=bash

subcmd="${1:-}"

strip_ansi() {
	if command -v ansi2txt >/dev/null 2>&1; then
		ansi2txt
	else
		sed -E $'s/\x1b\\[[0-9;]*[a-zA-Z]//g'
	fi
}

run_preview() {
	local cache_dir="$1"
	local raw_item="$2"

	local rev
	rev="$(printf '%s\n' "$raw_item" | cut --delimiter ' ' --fields 2 --only-delimited | strip_ansi)"
	if [ -z "$rev" ]; then
		exit 0
	fi

	# Record current focus
	printf '%s' "$rev" >"$cache_dir/current_focus.tmp"
	mv "$cache_dir/current_focus.tmp" "$cache_dir/current_focus"

	# Fast-path: display cached translation output immediately
	if [ -f "$cache_dir/$rev.out" ]; then
		cat "$cache_dir/$rev.out"
		exit 0
	fi

	# Unfinished translation: render with context-aware placeholder
	local placeholder="翻訳待機中 (PLaMo-3)..."
	if [ -f "$cache_dir/$rev.translating" ]; then
		placeholder="翻訳中 (PLaMo-3)..."
	elif [ -f "$cache_dir/service_down" ]; then
		placeholder="PLaMo-3 サービス未起動 (systemctl --user start llama-plamo)"
	fi

	git-show-ja --placeholder "$placeholder" --color=always "$rev" |
		riff --color=on |
		bat --language=gitlog --color=always --style=plain --wrap=character
}

run_worker() {
	local cache_dir="$1"
	local fzf_sock="$2"

	local port="${PLAMO_PORT:-18080}"
	local server_url="http://127.0.0.1:${port}"

	local prev_focus=""
	local focus_start=0

	while [ -d "$cache_dir" ]; do
		# Fail-closed health check for local translation service
		if ! curl --silent --fail --max-time 0.2 "${server_url}/health" >/dev/null 2>&1; then
			touch "$cache_dir/service_down"
			sleep 0.5
			continue
		else
			rm -f "$cache_dir/service_down"
		fi

		if [ -f "$cache_dir/current_focus" ]; then
			local current
			current="$(cat "$cache_dir/current_focus" 2>/dev/null || true)"
			local now
			now=$(date +%s%3N)

			if [ "$current" != "$prev_focus" ]; then
				prev_focus="$current"
				focus_start=$now
			elif [ -n "$current" ] && [ ! -f "$cache_dir/$current.out" ] && [ ! -f "$cache_dir/$current.translating" ]; then
				local elapsed=$((now - focus_start))
				# Debounce: queue translation once stayed for >= 100ms
				if [ "$elapsed" -ge 100 ]; then
					touch "$cache_dir/$current.translating"

					if [ -S "$fzf_sock" ]; then
						curl --silent --unix-socket "$fzf_sock" http -d 'refresh-preview' >/dev/null 2>&1 || true
					fi

					if git-show-ja --color=always "$current" 2>/dev/null |
						riff --color=on |
						bat --language=gitlog --color=always --style=plain --wrap=character >"$cache_dir/$current.out.tmp" 2>/dev/null; then
						mv "$cache_dir/$current.out.tmp" "$cache_dir/$current.out"
						rm -f "$cache_dir/$current.translating"

						if [ -S "$fzf_sock" ]; then
							curl --silent --unix-socket "$fzf_sock" http -d 'refresh-preview' >/dev/null 2>&1 || true
						fi
					else
						rm -f "$cache_dir/$current.translating"
					fi
				fi
			fi
		fi

		# Sleep 30ms to follow interactive keystrokes responsively
		sleep 0.03
	done
}

run_detail() {
	local cache_dir="$1"
	local rev="$2"

	if [ -f "$cache_dir/$rev.out" ]; then
		cat "$cache_dir/$rev.out"
	else
		git-show-ja --color=always "$rev" | riff --color=on | bat --language=gitlog --color=always --style=plain --wrap=character
	fi
}

run_main() {
	local query="${1:-}"

	local cache_dir
	cache_dir="$(mktemp -d "${TMPDIR:-/tmp}/git-log-fzf-ja.XXXXXX")"
	local fzf_sock="$cache_dir/fzf.sock"

	local self
	self="$(command -v "$0" || echo "$0")"

	cleanup() {
		if [ -n "${worker_pid:-}" ]; then
			kill "$worker_pid" 2>/dev/null || true
		fi
		rm -rf "$cache_dir"
	}
	trap cleanup EXIT INT TERM

	"$self" _worker "$cache_dir" "$fzf_sock" &
	local worker_pid=$!

	_fzf_git_fzf() {
		local -r q="$1"

		fzf --query "$q" \
			--height 50% --tmux 90%,70% \
			--layout reverse --multi --min-height 20+ --border \
			--no-separator --header-border horizontal \
			--border-label-pos 2 \
			--color 'label:blue' \
			--preview-window 'right,50%' --preview-border line \
			--bind 'ctrl-/:change-preview-window(down,50%|hidden|)' "$@"
	}

	git-log-simple | _fzf_git_fzf --ansi --nth 1,3.. --no-sort --query "$query" --border-label '🪵 Logs (ja)' \
		--listen="$fzf_sock" \
		--preview "$self _preview '$cache_dir' {}" \
		--header $'CTRL-O (Open in browser) / CTRL-R (Revert)\nEnter (Detail)\n\n' \
		--bind 'ctrl-o:execute-silent(gh browse {2})' \
		--bind 'ctrl-r:become(git revert {2})' \
		--bind "enter:become($self _detail '$cache_dir' {2})"
}

case "$subcmd" in
_preview)
	shift
	run_preview "$@"
	;;
_worker)
	shift
	run_worker "$@"
	;;
_detail)
	shift
	run_detail "$@"
	;;
*)
	run_main "$@"
	;;
esac

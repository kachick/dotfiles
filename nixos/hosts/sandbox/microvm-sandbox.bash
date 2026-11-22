#!/usr/bin/env bash
set -euo pipefail

MICROVM_RUN="${MICROVM_RUN:-}"
if [ -z "$MICROVM_RUN" ] || [ ! -x "$MICROVM_RUN" ]; then
	echo "error: MICROVM_RUN is not set or not executable" >&2
	exit 1
fi

STATE_ROOT="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/microvm-sandbox"
DEFAULT_NAME="default"
PORT_START=2221
PORT_END=2320
BOOT_TIMEOUT_SECONDS=30

usage() {
	cat <<'EOF'
Usage:
  microvm-sandbox [console]
  microvm-sandbox up [NAME]
  microvm-sandbox exec [NAME] -- <COMMAND...>
  microvm-sandbox ssh [NAME]
  microvm-sandbox status
  microvm-sandbox down [NAME|--all]
EOF
}

validate_name() {
	local name="$1"
	if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
		echo "error: invalid instance name: $name" >&2
		exit 1
	fi
}

state_dir_for() {
	printf '%s/%s\n' "$STATE_ROOT" "$1"
}

is_running() {
	local pid_file="$1"
	if [ ! -f "$pid_file" ]; then
		return 1
	fi
	local pid
	pid="$(cat "$pid_file")"
	[[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null
}

port_in_use() {
	local port="$1"
	if ss -Htl --numeric "sport = :${port}" | grep -q .; then
		return 0
	fi
	local port_file
	for port_file in "$STATE_ROOT"/*/ssh.port; do
		[ -f "$port_file" ] || continue
		if [ "$(cat "$port_file")" = "$port" ]; then
			local dir
			dir="$(dirname "$port_file")"
			if is_running "${dir}/qemu.pid"; then
				return 0
			fi
		fi
	done
	return 1
}

find_free_port() {
	local port
	for ((port = PORT_START; port <= PORT_END; port++)); do
		if ! port_in_use "$port"; then
			printf '%s\n' "$port"
			return 0
		fi
	done
	echo "error: no free local port in ${PORT_START}-${PORT_END}" >&2
	return 1
}

# Disable ControlMaster so restarted instances reusing a port never hit stale sockets.
ssh_base_args() {
	local port="$1"
	SSH_ARGS=(
		-o StrictHostKeyChecking=no
		-o UserKnownHostsFile=/dev/null
		-o LogLevel=ERROR
		-o ControlMaster=no
		-o ControlPath=none
		-o PasswordAuthentication=no
		-o ConnectTimeout=5
		-p "$port"
	)
}

patch_runner() {
	local name="$1"
	local port="$2"
	local state_dir="$3"
	local patched_runner="${state_dir}/microvm-run"

	local required_tokens=(
		"-name sandbox"
		"-chardev 'stdio,id=stdio,signal=off'"
		"-serial chardev:stdio"
		"-netdev 'user,id=net0'"
	)
	local token
	for token in "${required_tokens[@]}"; do
		if ! grep -Fq -- "$token" "$MICROVM_RUN"; then
			echo "error: unexpected microvm-run format; missing token: $token" >&2
			return 1
		fi
	done

	sed \
		-e "s|-name sandbox|-name 'sandbox-${name}'|" \
		-e "s|-chardev 'stdio,id=stdio,signal=off'||" \
		-e "s|-serial chardev:stdio|-serial 'file:${state_dir}/console.log' -daemonize -pidfile '${state_dir}/qemu.pid'|" \
		-e "s|-netdev 'user,id=net0'|-netdev 'user,id=net0,hostfwd=tcp:127.0.0.1:${port}-:22'|" \
		"$MICROVM_RUN" >"$patched_runner"
	chmod +x "$patched_runner"
}

stop_instance() {
	local name="$1"
	local state_dir
	state_dir="$(state_dir_for "$name")"

	if [ ! -d "$state_dir" ]; then
		echo "error: instance '$name' is not found" >&2
		return 1
	fi

	local pid_file="${state_dir}/qemu.pid"
	if is_running "$pid_file"; then
		local pid
		pid="$(cat "$pid_file")"
		kill -TERM "$pid" 2>/dev/null || true

		local i
		for ((i = 0; i < 25; i++)); do
			if ! kill -0 "$pid" 2>/dev/null; then
				break
			fi
			sleep 0.2
		done

		if kill -0 "$pid" 2>/dev/null; then
			kill -KILL "$pid" 2>/dev/null || true
		fi
	fi

	rm -rf "$state_dir"
	echo "stopped $name"
}

cmd_up() {
	local name="${1:-$DEFAULT_NAME}"
	validate_name "$name"

	local state_dir
	state_dir="$(state_dir_for "$name")"
	local pid_file="${state_dir}/qemu.pid"
	local port_file="${state_dir}/ssh.port"

	if is_running "$pid_file"; then
		echo "already running $name (pid=$(cat "$pid_file"), port=$(cat "$port_file" 2>/dev/null || echo unknown))"
		return 0
	fi

	rm -rf "$state_dir"
	mkdir -p "$state_dir"

	local port
	port="$(find_free_port)"
	printf '%s\n' "$port" >"$port_file"

	if ! patch_runner "$name" "$port" "$state_dir"; then
		rm -rf "$state_dir"
		return 1
	fi

	"${state_dir}/microvm-run"

	ssh_base_args "$port"
	local elapsed
	for ((elapsed = 0; elapsed < BOOT_TIMEOUT_SECONDS; elapsed++)); do
		if ! is_running "$pid_file"; then
			echo "error: instance '$name' exited during boot" >&2
			if [ -f "${state_dir}/console.log" ]; then
				tail -n 20 "${state_dir}/console.log" >&2
			fi
			rm -rf "$state_dir"
			return 1
		fi

		if ssh "${SSH_ARGS[@]}" -o BatchMode=yes user@127.0.0.1 true 2>/dev/null; then
			echo "started $name (pid=$(cat "$pid_file"), port=$port)"
			return 0
		fi
		sleep 1
	done

	echo "error: timed out waiting for SSH on $name (127.0.0.1:${port}); check ${state_dir}/console.log" >&2
	return 1
}

require_running_port() {
	local name="$1"
	local state_dir
	state_dir="$(state_dir_for "$name")"

	if ! is_running "${state_dir}/qemu.pid"; then
		echo "error: instance '$name' is not running" >&2
		return 1
	fi

	if [ ! -f "${state_dir}/ssh.port" ]; then
		echo "error: missing ssh.port for instance '$name'" >&2
		return 1
	fi

	cat "${state_dir}/ssh.port"
}

cmd_exec() {
	local name="$DEFAULT_NAME"
	if [ $# -eq 0 ]; then
		usage >&2
		exit 1
	fi

	if [ "$1" = "--" ]; then
		shift
	else
		name="$1"
		shift
		if [ $# -eq 0 ] || [ "$1" != "--" ]; then
			echo "error: expected '--' before command" >&2
			usage >&2
			exit 1
		fi
		shift
	fi

	if [ $# -eq 0 ]; then
		echo "error: missing command after '--'" >&2
		usage >&2
		exit 1
	fi

	validate_name "$name"
	local port
	port="$(require_running_port "$name")"
	ssh_base_args "$port"
	exec ssh "${SSH_ARGS[@]}" -o BatchMode=yes user@127.0.0.1 -- "$@"
}

cmd_ssh() {
	local name="${1:-$DEFAULT_NAME}"
	validate_name "$name"
	local port
	port="$(require_running_port "$name")"
	ssh_base_args "$port"
	exec ssh "${SSH_ARGS[@]}" user@127.0.0.1
}

cmd_status() {
	if [ ! -d "$STATE_ROOT" ]; then
		echo "No microvm-sandbox instances."
		return 0
	fi

	local found=0
	local dir
	for dir in "$STATE_ROOT"/*; do
		[ -d "$dir" ] || continue
		if [ "$found" -eq 0 ]; then
			printf '%-20s %-10s %-10s %s\n' "NAME" "STATE" "PID" "PORT"
			found=1
		fi
		local name state pid port
		name="$(basename "$dir")"
		port="$(cat "${dir}/ssh.port" 2>/dev/null || echo "-")"
		if is_running "${dir}/qemu.pid"; then
			state="running"
			pid="$(cat "${dir}/qemu.pid")"
		else
			state="stopped"
			pid="-"
		fi
		printf '%-20s %-10s %-10s %s\n' "$name" "$state" "$pid" "$port"
	done

	if [ "$found" -eq 0 ]; then
		echo "No microvm-sandbox instances."
	fi
}

cmd_down() {
	if [ "${1:-}" = "--all" ]; then
		if [ ! -d "$STATE_ROOT" ]; then
			return 0
		fi
		local dir
		for dir in "$STATE_ROOT"/*; do
			[ -d "$dir" ] || continue
			stop_instance "$(basename "$dir")"
		done
		return 0
	fi

	local name="${1:-$DEFAULT_NAME}"
	validate_name "$name"
	stop_instance "$name"
}

subcommand="${1:-console}"
if [ $# -gt 0 ]; then
	shift
fi

case "$subcommand" in
console)
	exec "$MICROVM_RUN" "$@"
	;;
up)
	cmd_up "$@"
	;;
exec)
	cmd_exec "$@"
	;;
ssh)
	cmd_ssh "$@"
	;;
status)
	cmd_status "$@"
	;;
down)
	cmd_down "$@"
	;;
-h | --help | help)
	usage
	;;
*)
	echo "error: unknown subcommand: $subcommand" >&2
	usage >&2
	exit 1
	;;
esac

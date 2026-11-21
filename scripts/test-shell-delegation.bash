#!/usr/bin/env bash

set -euo pipefail

: "${BASHRC_FILE:?}"
: "${BASH_PROFILE_FILE:?}"
: "${HERDR_CONFIG_FILE:?}"
: "${ZELLIJ_CONFIG_FILE:?}"
: "${BASH_BIN:?}"
: "${ZSH_BIN:?}"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

TEST_HOME="$WORKDIR/home"
TEST_LOG="$WORKDIR/test.log"
export TEST_LOG

mkdir -p \
	"$TEST_HOME/.config/herdr" \
	"$TEST_HOME/.config/zellij" \
	"$TEST_HOME/.local/state/bash" \
	"$TEST_HOME/.local/state/zsh" \
	"$WORKDIR/zsock" \
	"$WORKDIR/zrun" \
	"$WORKDIR/zcache"

cp "$BASHRC_FILE" "$TEST_HOME/.bashrc"
cp "$BASH_PROFILE_FILE" "$TEST_HOME/.bash_profile"
cp "$HERDR_CONFIG_FILE" "$TEST_HOME/.config/herdr/config.toml"
cp "$ZELLIJ_CONFIG_FILE" "$TEST_HOME/.config/zellij/config.kdl"
chmod u+w "$TEST_HOME/.bashrc" "$TEST_HOME/.bash_profile" "$TEST_HOME/.config/herdr/config.toml" "$TEST_HOME/.config/zellij/config.kdl"

# Disable background network checks in offline nix-build sandbox.
cat >>"$TEST_HOME/.config/herdr/config.toml" <<'EOF'

[update]
version_check = false
manifest_check = false
EOF

cat >"$TEST_HOME/.zshrc" <<'EOF'
[[ -o login ]] && _mode=login || _mode=nonlogin
printf 'RESULT=zsh:%s:%s\n' "$_mode" "$SHLVL" >> "${TEST_LOG}"
if [[ -n "${TEST_EXIT_ON_ZSH:-}" ]]; then
  exit 0
fi
PS1='TEST_ZSH> '
EOF

reset_log() {
	: >"$TEST_LOG"
}

assert_log_line() {
	local -r name="$1"
	local -r expected="$2"
	local actual
	actual="$(tr '\n' ' ' <"$TEST_LOG")"
	if ! grep -Fxq "$expected" "$TEST_LOG"; then
		echo "FAIL [$name]: expected line '$expected', got: [$actual]" >&2
		exit 1
	fi
	echo "PASS [$name]: $expected"
}

run_expect_shell() {
	local -a env_args=()
	while [[ $# -gt 0 && "$1" == *=* ]]; do
		env_args+=("$1")
		shift
	done
	env -i HOME="$TEST_HOME" PATH="$PATH" TERM=dumb SHELL="$BASH_BIN" TEST_LOG="$TEST_LOG" TEST_EXIT_ON_ZSH=1 "${env_args[@]}" \
		expect -f - "$@" <<'EOF' >/dev/null
log_user 0
set timeout 10
spawn -noecho {*}$argv
expect {
  -re {\$ ?$} {
    send "printf 'RESULT=bash:%s\\n' \"\$SHLVL\" >> \"\$TEST_LOG\"; exit\r"
    expect eof
  }
  eof {}
  timeout {
    puts stderr "expect timed out for command: $argv"
    exit 1
  }
}
EOF
}

# 1. Top-level login bash (SHLVL unset -> bash decrements on exec -> zsh SHLVL=1)
reset_log
run_expect_shell "$BASH_BIN" --login -i
assert_log_line "top-level login bash" "RESULT=zsh:login:1"

# 2. Login bash started with inherited SHLVL=1 (launcher from existing shell -> zsh SHLVL=2)
reset_log
run_expect_shell SHLVL=1 "$BASH_BIN" --login -i
assert_log_line "login bash with SHLVL=1" "RESULT=zsh:login:2"

# 3. Top-level non-login interactive bash (podman exec style, SHLVL unset -> zsh SHLVL=1)
reset_log
run_expect_shell "$BASH_BIN" -i
assert_log_line "top-level non-login interactive bash" "RESULT=zsh:nonlogin:1"

# 4. Manual `bash` from zsh (trailing `; :` prevents zsh -c tail-call exec optimization) -> stay in bash
reset_log
run_expect_shell "$ZSH_BIN" -c "'$BASH_BIN' -i; :"
assert_log_line "manual bash from zsh" "RESULT=bash:2"

# 5. Manual `bash --login` from zsh (parent=zsh) -> stay in bash
reset_log
run_expect_shell "$ZSH_BIN" -c "'$BASH_BIN' --login -i; :"
assert_log_line "manual login bash from zsh" "RESULT=bash:2"

# 6. Non-interactive `bash -lc` -> stay in bash without triggering zsh
reset_log
out_cmd="$(env -i HOME="$TEST_HOME" PATH="$PATH" TERM=dumb SHELL="$BASH_BIN" TEST_LOG="$TEST_LOG" \
	"$BASH_BIN" -lc "printf '%s' \"\${BASH_VERSION:+bash}\"")"
if [[ "$out_cmd" != "bash" ]] || [[ -s "$TEST_LOG" ]]; then
	echo "FAIL [bash -lc]: unexpected output '$out_cmd' or log" >&2
	exit 1
fi
echo "PASS [non-interactive bash -lc]: bash"

# 7. nix develop style `bash --rcfile` with SHLVL=2 (parent != zsh) -> stay in bash
reset_log
printf 'source "%s"\n' "$TEST_HOME/.bashrc" >"$WORKDIR/dev_rc.bash"
run_expect_shell SHLVL=2 "$BASH_BIN" --rcfile "$WORKDIR/dev_rc.bash" -i
assert_log_line "nix develop style bash --rcfile" "RESULT=bash:3"

# 8. Real herdr E2E (shell_mode = "login", launched with SHLVL=1) -> zsh --login
reset_log
cat >"$WORKDIR/run_herdr.bash" <<'EOF'
herdr server >/dev/null 2>&1 &
srv_pid=$!
for _ in $(seq 1 50); do
	if herdr status >/dev/null 2>&1; then break; fi
	sleep 0.1
done
herdr workspace create --label e2e >/dev/null
for _ in $(seq 1 50); do
	if grep -q "^RESULT=" "$TEST_LOG" 2>/dev/null; then break; fi
	sleep 0.1
done
herdr server stop >/dev/null 2>&1 || kill "$srv_pid" 2>/dev/null || true
wait "$srv_pid" 2>/dev/null || true
EOF
env -i HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" PATH="$PATH" TERM=xterm-256color SHELL="$BASH_BIN" SHLVL=1 TEST_LOG="$TEST_LOG" \
	"$BASH_BIN" "$WORKDIR/run_herdr.bash"
assert_log_line "herdr login pane" "RESULT=zsh:login:2"

# 9. Real zellij E2E (no default_shell, launched with SHLVL=1) -> zsh nonlogin
reset_log
cat >"$WORKDIR/run_zellij.bash" <<'EOF'
script -qefc "timeout 5 zellij --config-dir \"$HOME/.config/zellij\" -s e2e-test" /dev/null >/dev/null 2>&1 &
z_pid=$!
for _ in $(seq 1 50); do
	if grep -q "^RESULT=" "$TEST_LOG" 2>/dev/null; then break; fi
	sleep 0.1
done
zellij kill-session e2e-test >/dev/null 2>&1 || true
wait "$z_pid" 2>/dev/null || true
EOF
env -i HOME="$TEST_HOME" XDG_CONFIG_HOME="$TEST_HOME/.config" ZELLIJ_SOCKET_DIR="$WORKDIR/zsock" XDG_RUNTIME_DIR="$WORKDIR/zrun" XDG_CACHE_HOME="$WORKDIR/zcache" PATH="$PATH" TERM=xterm-256color SHELL="$BASH_BIN" SHLVL=1 TEST_LOG="$TEST_LOG" \
	"$BASH_BIN" "$WORKDIR/run_zellij.bash"
assert_log_line "zellij default pane" "RESULT=zsh:nonlogin:2"

# 10. Manual `bash` inside zellij zsh pane (ZELLIJ=0, zsh SHLVL=2 -> bash SHLVL=3, parent=zsh) -> stay in bash
reset_log
run_expect_shell ZELLIJ=0 SHLVL=1 "$ZSH_BIN" -c "'$BASH_BIN' -i; :"
assert_log_line "manual bash inside zellij zsh pane" "RESULT=bash:3"

echo "All shell delegation E2E tests passed!"

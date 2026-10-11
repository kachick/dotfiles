#!/usr/bin/env bash

set -euxo pipefail

MONITOR_SOCK="/tmp/qemu-river-monitor.sock"
SCREEN_PPM="/tmp/river-screen.ppm"
SCREEN_PNG="/tmp/river-screen.png"

rm -f "${MONITOR_SOCK}" "${SCREEN_PPM}" "${SCREEN_PNG}"

# Ensure VM runner is built
nix build --out-link result-river-vm .#nixosConfigurations.river-vm.config.system.build.vm

# Run VM headlessly with QEMU monitor socket
export QEMU_OPTS="-display none -monitor unix:${MONITOR_SOCK},server,nowait"
./result-river-vm/bin/run-river-vm-vm &
VM_PID=$!

cleanup() {
	if kill -0 "${VM_PID}" 2>/dev/null; then
		kill -9 "${VM_PID}" || true
	fi
	rm -f "${MONITOR_SOCK}" "${SCREEN_PPM}"
}
trap cleanup EXIT

# Wait for boot, greetd auto-login, river startup, and ghostty launch
sleep 25

# Take screenshot and quit cleanly via QEMU monitor using Ruby
ruby -rsocket -e '
  UNIXSocket.open(ARGV[0]) do |s|
    s.puts "screendump #{ARGV[1]}"
    sleep 1
    s.puts "quit"
  end
' "${MONITOR_SOCK}" "${SCREEN_PPM}"

# Wait for QEMU to finish cleanly
wait "${VM_PID}" || true

# Convert PPM to PNG for inspection
nix shell 'nixpkgs#imagemagick' --command magick "${SCREEN_PPM}" "${SCREEN_PNG}"

if [ -s "${SCREEN_PNG}" ]; then
	echo "SUCCESS: Screenshot captured at ${SCREEN_PNG}"
else
	echo "FAILURE: Screenshot was not captured"
	exit 1
fi

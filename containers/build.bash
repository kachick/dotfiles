#!/usr/bin/env -S bash

set -euxo pipefail

build() {
	local stream_path
	stream_path="$(nix build .#container-layered.passthru.stream --no-link --print-out-paths)"
	"$stream_path" | podman load
}

build

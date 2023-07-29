#!/usr/bin/env bash

# Keep under 120ms for main shells...!
bench_shells() {
	hyperfine 'zsh -i -c exit'
	# Really having same options as zsh...?
	hyperfine 'bash -i -c exit'
	hyperfine 'nu -i -c exit'
}

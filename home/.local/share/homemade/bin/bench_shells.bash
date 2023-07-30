#!/usr/bin/env bash

set -euo pipefail

# ~ my feeling ~
# 50ms : blazing fast!
# 120ms : acceptable
# 200ms : 1980s?
# 300ms : slow!

hyperfine 'zsh -i -c exit'
# Really having same options as zsh...?
hyperfine 'bash -i -c exit'
hyperfine 'nu -i -c exit'

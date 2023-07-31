#!/usr/bin/env bash

set -euo pipefail

# ~ my feeling ~
# 50ms : blazing fast!
# 120ms : acceptable
# 200ms : 1980s?
# 300ms : slow!

hyperfine 'bash -i -c exit'
hyperfine 'zsh --interactive -c exit'
hyperfine 'fish --interactive --command exit'
hyperfine 'nu --interactive --commands exit'

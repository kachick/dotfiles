#!/usr/bin/env bash

set -euxo pipefail

# ~ my feeling ~
# 50ms : blazing fast!
# 120ms : acceptable
# 200ms : 1980s?
# 300ms : slow!

hyperfine --warmup 1 'bash -i -c exit'
hyperfine --warmup 1 'zsh --interactive -c exit'
hyperfine --warmup 1 'fish --interactive --command exit'
hyperfine --warmup 1 'nu --interactive --commands exit'

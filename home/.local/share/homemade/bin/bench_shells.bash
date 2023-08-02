#!/usr/bin/env bash

set -euxo pipefail

# ~ my feeling ~
# 50ms : blazing fast!
# 110ms : acceptable
# 150ms : slow
# 200ms : 1980s?
# 300ms : much slow!

# zsh should be first, because it often makes much slower with the completion
hyperfine --warmup 1 'zsh --interactive -c exit'

hyperfine --warmup 1 'bash -i -c exit'
hyperfine --warmup 1 'fish --interactive --command exit'

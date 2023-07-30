#!/usr/bin/env bash

set -euo pipefail

exa --long --all --group-directories-first "$@"

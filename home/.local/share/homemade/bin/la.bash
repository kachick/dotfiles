#!/usr/bin/env bash

set -euxo pipefail

exa --long --all --group-directories-first "$@"

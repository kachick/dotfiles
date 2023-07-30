#!/usr/bin/env bash

set -euo pipefail

name="$(basename "$PWD")"

zellij attach "$name" || zellij --session "$name"

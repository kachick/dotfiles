#!/usr/bin/env bash

set -euxo pipefail

name="$(basename "$PWD")"

zellij attach "$name" || zellij --session "$name"

#!/usr/bin/env bash

set -euo pipefail

case ${OSTYPE} in
linux*)
	sudo apt update --yes && sudo apt upgrade --yes
	;;
darwin*)
	softwareupdate --install --recommended
	;;
esac

nix-channel --update
home-manager switch

if command -v rtx; then
	rtx self-update
	rtx plugins update
fi

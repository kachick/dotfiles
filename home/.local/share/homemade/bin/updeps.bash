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

rtx plugins update

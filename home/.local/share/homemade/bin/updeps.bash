#!/usr/bin/env bash

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

if type 'sheldon' >/dev/null; then
	sheldon lock --update
fi
if command -v rtx; then
	rtx self-update
	rtx plugins update
fi

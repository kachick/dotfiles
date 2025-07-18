if [ -f /etc/NIXOS ]; then
	echo 'Needless this updater for NixOS, so exit with nothing'
	exit 1
fi

echo 'this updater assume you have the privilege and sudo command'

set -x

case "$OSTYPE" in
linux*)
	sudo apt update --yes && sudo apt upgrade --yes
	;;
darwin*)
	softwareupdate --install --recommended
	;;
esac

sudo -i nix upgrade-nix

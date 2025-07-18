set -x

if [ -e '/etc/NIXOS' ] || [ "$(uname)" != 'Linux' ]; then
	echo 'You can use this script only for non NixOS Linux'
	exit 2
fi

set -e

# [home-manager installed OpenSSH disabled GSSAPI by default](https://github.com/kachick/dotfiles/issues/950).
# So suppress `/etc/ssh/ssh_config line 53: Unsupported option "gssapiauthentication"` with following command
chmod a-r /etc/ssh/ssh_config

# Workaround for `-bash: warning: setlocale: LC_TIME: cannot change locale (en_DK.UTF-8): No such file or directory`
localedef -f UTF-8 -i en_DK en_DK.UTF-8

# Might be put code below which requires to inject Nix Store PATH

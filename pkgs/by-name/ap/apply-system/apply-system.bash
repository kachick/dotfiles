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
# WHY NOT use default localedef without --no-archive:
# Calling localedef without an archive target with root privileges writes into
# $out/lib/locale/locale-archive in the Nix store instead of the host system,
# which corrupts the Nix store path and breaks NAR hash verification.
# Passing --no-archive writes the compiled locale to the target directory
# (/usr/lib/locale/en_DK.UTF-8) without touching the Nix store, and host glibc
# (Ubuntu/Debian) reads unarchived locale directories under /usr/lib/locale.
mkdir -p /usr/lib/locale
localedef --no-archive -f UTF-8 -i en_DK /usr/lib/locale/en_DK.UTF-8
localedef --no-archive -f UTF-8 -i ja_JP /usr/lib/locale/ja_JP.UTF-8

# Might be put code below which requires to inject Nix Store PATH

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
# WHY NOT use Nix glibc localedef:
# Calling Nix's localedef with root privileges writes into $out/lib/locale/locale-archive
# in the Nix store instead of the host system, which corrupts the store path and breaks
# NAR hash verification in binary caches.
localedef_bin=""
for p in /usr/bin/localedef /bin/localedef; do
	if [ -x "$p" ]; then
		localedef_bin="$p"
		break
	fi
done

if [ -n "$localedef_bin" ]; then
	"$localedef_bin" -f UTF-8 -i en_DK en_DK.UTF-8
else
	echo 'WARNING: localedef not found on host. Install "locales" or "libc-bin" package to suppress LC_TIME warnings.' >&2
fi

# Might be put code below which requires to inject Nix Store PATH

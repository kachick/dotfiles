{ config, lib, ... }:

{
  # In Lima v2.x, the guest home directory for Linux is /home/<user>.guest
  # (previously /home/<user>.linux in Lima v1.x).
  # See https://github.com/lima-vm/lima/blob/v2.3.0/pkg/limayaml/defaults.go
  home.homeDirectory = "/home/${config.home.username}.guest";

  # The host repos mount (e.g., /home/kachick/repos) is read-only at the root level,
  # or may not exist in a scoped sandbox. Disable repos/.keep to avoid permission errors.
  home.file."repos/.keep".enable = false;

  # Restore access from the guest home to the host-path mounts.
  # This allows 'limactl shell' to sync CWD (via absolute host paths) while keeping
  # compatibility with tools expecting '~/repos' such as ghq and cdrepo.
  home.activation.setupHostReposSymlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for d in /home/*; do
      # 1. Skip if it's the current guest home (e.g., /home/user.guest)
      # 2. Check if 'repos' directory exists inside it (the host mount point)
      if [ "$d" != "$HOME" ] && [ -d "$d/repos" ]; then
        $DRY_RUN_CMD ln -sfn "$d/repos" "$HOME/repos"
        break
      fi
    done
  '';
}

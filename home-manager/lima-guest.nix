{ config, lib, ... }:

{
  # https://github.com/lima-vm/lima/blame/0d058b0eaa2d1bafc867298503a9239e89c202a8/templates/default.yaml#L295-L296
  home.homeDirectory = "/home/${config.home.username}.linux";

  # Restore access from the guest home to the host-path mounts.
  # This allows 'limactl shell' to sync CWD (via absolute host paths) while keeping
  # compatibility with tools expecting '~/repos' such as ghq and cdrepo.
  home.activation.setupHostReposSymlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for d in /home/*; do
      # 1. Skip if it's the current guest home (e.g., /home/user.linux)
      # 2. Check if 'repos' directory exists inside it (the host mount point)
      if [ "$d" != "$HOME" ] && [ -d "$d/repos" ]; then
        $DRY_RUN_CMD ln -sfn "$d/repos" "$HOME/repos"
        break
      fi
    done
  '';
}

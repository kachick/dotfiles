{ ... }:

{
  # https://github.com/nix-community/home-manager/blob/release-26.05/modules/systemd.nix#L287-L299
  systemd = {
    user = {
      # GNOME and other DE respect this `environment.d` values
      sessionVariables = {
        # Enable locale for GNOME and terminals in the gnome-shell. Linux VT console respects home.sessionVariables instead
        # https://superuser.com/a/1841368
        # https://github.com/nix-community/home-manager/blob/5ec753a1fc4454df9285d8b3ec0809234defb975/modules/systemd.nix#L92-L96
        # GNOME clock respects LC_TIME. And does not support displaying iso-8601 format even if set en_DK
        LC_TIME = "ja_JP.UTF-8";
      };
    };
  };
}

{ ... }:

{
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/misc/dconf.nix
  dconf.settings = {
    "org/gnome/shell/extensions/pop-shell" = {
      tile-by-default = true;
    };
  };
}

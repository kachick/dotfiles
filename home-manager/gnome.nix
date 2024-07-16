{ ... }:

{
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/misc/dconf.nix
  dconf = {
    enable = true;
    settings = {
      "org/gnome/shell" = {
        enabled-extensions = [
          "blur-my-shell@aunetx"
          "pop-shell@system76.com"
        ];
      };
      "org/gnome/shell/extensions/pop-shell" = {
        tile-by-default = true;
      };
    };
  };
}

{ ... }:
{
  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/misc/gtk.nix
  gtk = {
    enable = true;
    # https://fcitx-im.org/wiki/Using_Fcitx_5_on_Wayland
    gtk2.extraConfig = ''
      gtk-im-module=fcitx
    '';
    gtk3.extraConfig = {
      gtk-im-module = "fcitx";
    };
    gtk4.extraConfig = {
      gtk-im-module = "fcitx";
    };
  };
}

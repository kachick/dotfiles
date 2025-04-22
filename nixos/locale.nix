{ ... }:
{
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/config/i18n.nix
  # https://nixos.wiki/wiki/Locales
  i18n = {
    # GNOME respects this, I don't know how to realize it only via home-manager
    defaultLocale = "ja_JP.UTF-8";

    # Candidates: https://sourceware.org/git/?p=glibc.git;a=blob;f=localedata/SUPPORTED
    supportedLocales = [
      "C.UTF-8/UTF-8"
      "en_US.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
      "en_DK.UTF-8/UTF-8"
    ];

    extraLocaleSettings = {
      # FIXME: Don't set LC_TIME here, it makes strange and unstable behaviors. Correctly overridable in user systemd on algae and not working in moss. Even if both device have almost same config...
      # https://wiki.archlinux.jp/index.php/%E3%83%AD%E3%82%B1%E3%83%BC%E3%83%AB
      # LC_TIME = "en_DK.UTF-8"; # To prefer ISO 8601 format. See https://unix.stackexchange.com/questions/62316/why-is-there-no-euro-english-locale
    };
  };
}

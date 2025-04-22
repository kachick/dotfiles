{ ... }:
{
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/config/i18n.nix
  # https://nixos.wiki/wiki/Locales
  # https://wiki.archlinux.jp/index.php/%E3%83%AD%E3%82%B1%E3%83%BC%E3%83%AB
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
      # Don't set this in home-manager's sessionVariables. It makes much confusion behavior or bugs when using GNOME (or all of DE)
      LC_TIME = "en_DK.UTF-8"; # To prefer ISO 8601 format. See https://unix.stackexchange.com/questions/62316/why-is-there-no-euro-english-locale
    };
  };
}

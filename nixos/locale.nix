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

    # Don't set LC_TIME in extraLocaleSettings, overriding by each shell init hooks should be better for that context.
  };
}

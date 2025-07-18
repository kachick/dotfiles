{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = true;

    # Provide dir for easy useable fc-query
    # For getting font family name
    # ```bash
    # cd /nix/var/nix/profiles/system/sw/share/X11/fonts
    # fc-query IBMPlexSansJP-Regular.otf | grep '^\s\+family:' | cut -d'"' -f2
    # ```
    fontDir.enable = true;

    packages = with pkgs; [
      ibm-plex
      plemoljp-nf
      inconsolata
      mplus-outline-fonts.githubRelease
      # sarasa-gothic # Drop this because of the large filesize

      # emoji
      noto-fonts-color-emoji
      twemoji-color-font
      beedii

      # Source Han family includes many definitions, useful for fallback
      source-han-code-jp
      source-han-sans-japanese
      source-han-serif-japanese
    ];

    # Same as home-manager module?
    # https://github.com/nix-community/home-manager/issues/605
    # https://github.com/nix-community/home-manager/blob/release-24.11/modules/misc/fontconfig.nix
    fontconfig = {
      enable = true;
      hinting.enable = true;
      # Set color emoji font for everywhere, not only for emoji
      # Without it often made troubles, such as chrome bookmarkbar uses monochrome emojis
      defaultFonts = {
        serif = [
          "IBM Plex Serif"
          "Source Han Serif"
          "Noto Color Emoji"
        ];
        sansSerif = [
          "IBM Plex Sans"
          "Source Han Sans"
          "Noto Color Emoji"
        ];
        monospace = [
          "PlemolJP Console NF"
          "Source Han Code JP"
          "Noto Color Emoji"
        ];
        emoji = [
          # monochrome fonts such as "Beedii" will be disabled by color fonts even in adjusted order
          "Noto Color Emoji"
        ];
      };
    };
  };
}

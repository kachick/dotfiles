{ pkgs, homemade-pkgs, ... }:
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

    packages =
      (with pkgs; [
        ibm-plex
        plemoljp-nf
        inconsolata
        mplus-outline-fonts.githubRelease
        # sarasa-gothic # Drop this because of the large filesize

        # emoji
        noto-fonts-color-emoji
        twemoji-color-font

        # Source Han family includes many definitions, useful for fallback
        source-han-code-jp
        source-han-sans-japanese
        source-han-serif-japanese
      ])
      ++ [
        # emoji
        homemade-pkgs.beedii
      ];

    # Same as home-manager module?
    # https://github.com/nix-community/home-manager/issues/605
    # https://github.com/nix-community/home-manager/blob/release-24.05/modules/misc/fontconfig.nix
    fontconfig = {
      enable = true;
      hinting.enable = true;
      defaultFonts = {
        serif = [
          "IBM Plex Serif"
          "Source Han Serif"
        ];
        sansSerif = [
          "IBM Plex Sans"
          "Source Han Sans"
        ];
        monospace = [
          "PlemolJP Console NF"
          "Source Han Code JP"
        ];
        emoji = [
          "Beedii"
          "Noto Color Emoji"
        ];
      };
    };
  };
}

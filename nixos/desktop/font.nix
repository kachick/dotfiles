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
      # IBM Plex family provides broad character coverage and I prefer its design.
      # While the Source Han series offers even more extensive fallback definitions,
      # adding them all leads to significant disk bloat.
      # Thus, I've opted for IBM Plex as the primary set and omitted most Source Han variants.
      local.ibm-plex-sans-jp
      local.ibm-plex-mono
      local.ibm-plex-serif-variable
      plemoljp-nf

      # emoji
      noto-fonts-color-emoji

      # Source Han family includes many definitions, useful for fallback.
      # Keep minimal packages for disk space.
      # Other fonts should be used on-demand in each repository or development environment:
      #   mplus-outline-fonts.githubRelease, inconsolata, beedii, biz-ud-gothic, ipamjfont, etc...
      source-han-sans
    ];

    # Same as home-manager module?
    # https://github.com/nix-community/home-manager/issues/605
    # https://github.com/nix-community/home-manager/blob/release-25.11/modules/misc/fontconfig.nix
    fontconfig = {
      enable = true;
      hinting.enable = true;
      # Set color emoji font for everywhere, not only for emoji
      # Without it often made troubles, such as chrome bookmarkbar uses monochrome emojis
      defaultFonts = {
        serif = [
          "IBM Plex Serif Var"
          "Source Han Sans" # Fallback to Sans if Serif not found
          "Noto Color Emoji"
        ];
        sansSerif = [
          "IBM Plex Sans JP"
          "Source Han Sans"
          "Noto Color Emoji"
        ];
        monospace = [
          "PlemolJP Console NF"
          "IBM Plex Mono" # Source Han Code JP is omitted to avoid disk bloat, despite its superior fallback coverage
          "Noto Color Emoji"
        ];
        emoji = [
          # NOTE: Monochrome emoji/symbol fonts (e.g. "Beedii") will be disabled by color fonts even in adjusted order
          "Noto Color Emoji"
        ];
      };
    };
  };
}

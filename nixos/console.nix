{ homemade-pkgs, ... }:
{
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/config/console.nix
  # https://wiki.archlinux.org/title/Linux_console
  console = {
    earlySetup = true;
    # The font should have PSF formats. Do not specify TTF and OTF
    # You can list current glyphs with `showconsolefont`
    font = "${homemade-pkgs.cozette}/share/consolefonts/cozette_hidpi.psf";

    packages = with homemade-pkgs; [ cozette ];
    keyMap = "us";

    # Applying iceberg for 16(0-15) console colors
    # Original schema is shared in https://gist.github.com/cocopon/1d481941907d12db7a0df2f8806cfd41
    # You can test as `echo -en "\e]P484a0c6"` the P4's "4" means blue. It is same as 0 start index 4 in this list
    # In hex, 12 will be C as "PC91acd1" for 12 index bright blue.
    colors = [
      # 0 - black
      "1e2132"

      # 1 - red
      "e27878"

      # 2 - green
      "b4be82"

      # 3 - yellow
      "e2a478"

      # 4 - blue. Should be changed to avoid unreadable ANSI blue. See GH-660
      "84a0c6"

      # 5 - magenta
      "a093c7"

      # 6 - cyan
      "89b8c2"

      # 7 - white
      "c6c8d1"

      # 8 - bright black
      "6b7089"

      # 9 - bright red
      "e98989"

      # 10 - bright green
      "c0ca8e"

      # 11 - bright yellow
      "e9b189"

      # 12 - bright blue
      "91acd1"

      # 13 -bright magenta
      "ada0d3"

      # 14 - bright cyan
      "95c4ce"

      # 15 - bright white
      "d2d4de"
    ];
  };
}

{ pkgs, ... }:
{
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/config/console.nix
  # https://wiki.archlinux.org/title/Linux_console
  console = {
    earlySetup = true;
    # The font should have PSF formats. Do not specify TTF and OTF
    # You can list current glyphs with `sudo showconsolefont`
    #
    # Avoiding cozette for now, it is not a monospace font and having problem https://github.com/the-moonwitch/Cozette/issues/122
    # A patch in nixpkgs https://github.com/NixOS/nixpkgs/pull/371226 does not completely resolve it for HiDPI files.
    # I guess the root cause is cozette have different wides for each gryph and it will not be fit for monospace specialized tools
    #
    # Requirements
    #   - monospace
    #   - For HiDPI. It should have 10x20 or larger (This excludes Gohufont)
    #
    # Candidates
    #   - spleen
    #   - Terminus
    font = "${pkgs.tamzen}/share/consolefonts/TamzenForPowerline10x20.psf";

    # https://github.com/NixOS/nixpkgs/pull/371226 is now available only on unstable
    packages = with pkgs; [
      tamzen
    ];

    # You might need to custom this, for example your device is having JIS layout keyboard.
    # The IDs are not same as X11 definitions. So check the model section in following path.
    #
    # ```bash
    # bat "$(nix build --no-link --print-out-paths github:NixOS/nixpkgs/nixos-25.05#xkeyboard_config)/etc/X11/xkb/rules/base.lst"
    # ```
    #
    # JIS should be "jp106", not "jp"
    keyMap = pkgs.lib.mkDefault "us"; # Cannot use multiple such as `us,jp106` in this option

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

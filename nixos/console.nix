# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ pkgs, ... }:
{
  # https://wiki.archlinux.org/title/Linux_console
  console = {
    earlySetup = true;
    # The font should have PSF formats. Do not specify TTF and OTF
    # You can list current glyphs with `showconsolefont`
    font = "ter-u24n";

    packages = with pkgs; [
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/pkgs/data/fonts/terminus-font/default.nix#L41-L43
      terminus_font
    ];
    keyMap = "us";
  };

  # Better console appearance even if no X, but do not use for now with the unstable behaviors
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/ttys/kmscon.nix
  services.kmscon = {
    enable = false;
    hwRender = false;
    fonts = with pkgs; [
      {
        name = "IBM Plex Mono";
        package = ibm-plex;
      }
      {
        name = "Noto Color Emoji";
        package = noto-fonts-color-emoji;
      }
    ];
    extraConfig = "font-size=24";
    extraOptions = "--term xterm-256color";
  };
}

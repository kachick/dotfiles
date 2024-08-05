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
    font = "${pkgs.cozette}/share/fonts/misc/cozette.psf";

    packages = with pkgs; [ cozette ];
    keyMap = "us";
  };
}

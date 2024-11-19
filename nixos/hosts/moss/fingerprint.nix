{ pkgs, ... }:
{
  services.fprintd = {
    enable = true;

    # https://gitlab.freedesktop.org/libfprint/libfprint/-/issues/402#note_1860665

    # https://discourse.nixos.org/t/cannot-enroll-fingerprints-with-fprintd-no-devices-available/40362
    tod = {
      enable = true;
      # This select is a bit different of https://github.com/ramaureirac/thinkpad-e14-linux/blob/7539f51b1c29d116a549265f992032aa9642d4a5/tweaks/fingerprint/README.md#L19
      # You should check actual vendor with `lsusb | grep FingerPrint`
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/development/libraries/libfprint-2-tod1-goodix-550a/default.nix#L9
      driver = pkgs.libfprint-2-tod1-goodix-550a;
    };

    # https://github.com/NixOS/nixpkgs/issues/298150
    # package = pkgs.fprintd.overrideAttrs {
    #   mesonCheckFlags = [
    #     "--no-suite"
    #     "fprintd:TestPamFprintd"
    #   ];
    # };
  };

  # https://sbulav.github.io/nix/nix-fingerprint-authentication/
  security.pam.services.swaylock = { };
  security.pam.services.swaylock.fprintAuth = true;
}

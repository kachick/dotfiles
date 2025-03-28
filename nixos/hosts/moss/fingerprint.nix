{ pkgs, ... }:
{
  services.fprintd = {
    enable = true;

    # https://gitlab.freedesktop.org/libfprint/libfprint/-/issues/402#note_1860665

    # https://discourse.nixos.org/t/cannot-enroll-fingerprints-with-fprintd-no-devices-available/40362
    tod = {
      enable = true;
      # You should check actual vendor with `lsusb | grep FingerPrint`
      # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/pkgs/by-name/li/libfprint-2-tod1-goodix-550a/package.nix
      # See https://github.com/ramaureirac/thinkpad-e14-linux/commit/2216fecbc7ca0a5cdd4e6bb720c4837164d9d952 for detail
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

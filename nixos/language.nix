# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:
{
  # Select internationalisation properties.
  i18n = {
    defaultLocale = "ja_JP.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "ja_JP.UTF-8";
      LC_IDENTIFICATION = "ja_JP.UTF-8";
      LC_MEASUREMENT = "ja_JP.UTF-8";
      LC_MONETARY = "ja_JP.UTF-8";
      LC_NAME = "ja_JP.UTF-8";
      LC_NUMERIC = "ja_JP.UTF-8";
      LC_PAPER = "ja_JP.UTF-8";
      LC_TELEPHONE = "ja_JP.UTF-8";
      LC_TIME = "ja_JP.UTF-8";
    };

    inputMethod = {
      enabled = "fcitx5";

      fcitx5.addons = [
        pkgs.fcitx5-mozc
        pkgs.fcitx5-gtk
      ];

      fcitx5.waylandFrontend = true;
    };
  };

  services.dbus.packages = [ config.i18n.inputMethod.package ];
}

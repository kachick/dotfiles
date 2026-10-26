{
  config,
  pkgs,
  lib,
  ...
}:

{
  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    packages = with pkgs; [
      # Fix missing locales as `locale: Cannot set LC_CTYPE to default locale`
      glibc
    ];
  };
}

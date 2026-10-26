{
  config,
  pkgs,
  lib,
  ...
}:

{
  home = {
    homeDirectory = lib.mkDefault "/home/${config.home.username}";

    sessionVariables = {
      # Make it possible to handle special terminfo such as "xterm-kitty" in SSH remotes or lima guest VM with tiny filesize and setups. See GH-932
      #
      # - Don't include `pkgs.ANYTTY` to avoid the build and or download large package. Use `pkgs.ANYTTY.terminfo`
      # - Don't remove terminfo even if it is outdated
      TERMINFO_DIRS = "${pkgs.kitty.terminfo}/share/terminfo:${pkgs.ghostty.terminfo}/share/terminfo";
    };

    packages = with pkgs; [
      # Fix missing locales as `locale: Cannot set LC_CTYPE to default locale`
      glibc
    ];
  };
}

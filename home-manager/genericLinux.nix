{ pkgs, ... }:
{
  # This also changes xdg? Official manual sed this config is better for non NixOS Linux
  # https://github.com/nix-community/home-manager/blob/559856748982588a9eda6bfb668450ebcf006ccd/modules/targets/generic-linux.nix#L16
  targets.genericLinux.enable = true;

  home = {
    sessionVariables = {
      # Make it possible to handle special terminfo such as "xterm-kitty" in SSH remotes or lima guest VM with tiny filesize and setups. See GH-932
      #
      # - Don't set this in NixOS desktop. It has own value
      # - Don't include `pkgs.ANYTTY` to avoid the build and or download large package. Use `pkgs.ANYTTY.terminfo`
      # - Don't remove termnfo even if it is outdated
      TERMINFO_DIRS = "${pkgs.kitty.terminfo}/share/terminfo:${pkgs.unstable.ghostty.terminfo}/share/terminfo";
    };

    locale = {
      time = "en_DK.UTF-8"; # To prefer ISO 8601 format. See https://unix.stackexchange.com/questions/62316/why-is-there-no-euro-english-locale

    };
  };
}

{ pkgs, ... }:
{
  # This also changes xdg? Official manual sed this config is better for non NixOS Linux
  # https://github.com/nix-community/home-manager/blob/559856748982588a9eda6bfb668450ebcf006ccd/modules/targets/generic-linux.nix#L16
  targets.genericLinux.enable = true;

  home = {
    sessionVariables = {
      # Make it possible to handle "xterm-kitty" in SSH remotes or lima guest VM with tiny filesize and setups. See GH-932
      #
      # Don't set this in NixOS desktop. It has own value.
      TERMINFO_DIRS = "${pkgs.kitty.terminfo}/share/terminfo:${pkgs.unstable.ghostty.terminfo}/share/terminfo";
    };
  };
}

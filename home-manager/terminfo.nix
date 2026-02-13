{ pkgs, ... }:
{
  home.sessionVariables = {
    # Make it possible to handle special terminfo such as "xterm-kitty" in SSH remotes or lima guest VM with tiny filesize and setups. See GH-932
    #
    # - Don't set this in NixOS desktop. It has own value
    # - Don't include `pkgs.ANYTTY` to avoid the build and or download large package. Use `pkgs.ANYTTY.terminfo`
    # - Don't remove terminfo even if it is outdated
    # - Including /usr/share/terminfo for Darwin
    TERMINFO_DIRS = "${pkgs.kitty.terminfo}/share/terminfo:${pkgs.ghostty.terminfo}/share/terminfo:/usr/share/terminfo";
  };
}

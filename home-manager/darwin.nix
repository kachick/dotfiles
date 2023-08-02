{ pkgs, ... }:

# condition branch as `if pkgs.stdenv.hostPlatform.isDarwin then` will not work, but having the config even in Linux okay for me.
{
  xdg.configFile."iterm2/com.googlecode.iterm2.plist".source = ../home/.config/iterm2/com.googlecode.iterm2.plist;

  # Just putting the refererenced file to easy import, applying should be done via GUI and saving to plist
  xdg.configFile."iterm2/OneHalfDark.itermcolors".text = builtins.readFile (
    pkgs.fetchFromGitHub
      {
        owner = "mbadolato";
        repo = "iTerm2-Color-Schemes";
        rev = "3f8a0791ed9a99c10054026c1a8285459117e0f2";
        sha256 = "sha256-ixryDwSNdVtD1H+V72V+hbFiL/JNLU4qpKXWflPQwrQ=";
      }
    + "/schemes/OneHalfDark.itermcolors"
  );
}

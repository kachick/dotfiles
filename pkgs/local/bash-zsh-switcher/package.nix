{
  lib,
  pkgs,
  replaceVars,
  ...
}:

# Actually this file is not a bash script, but dash mode is unuseful. Expecting mostly bash code will work even in zsh...
# Use replaceVars to enable basic shellscript helpers such as shfmt, shellcheck and syntax highlighters
#
# Note: Using `replaceVars` directly avoids Import From Derivation (IFD) which was caused by the previous `builtins.readFile` + `writeText` wrapper.
replaceVars ./bash-zsh-switcher.bash {
  ps = lib.getExe' pkgs.procps "ps";
  zsh = lib.getExe pkgs.zsh;
}

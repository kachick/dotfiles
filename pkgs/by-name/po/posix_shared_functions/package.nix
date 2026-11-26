{
  lib,
  pkgs,
  replaceVars,
  ...
}:
# https://unix.stackexchange.com/a/3449
# Use shared aliases in both bash and zsh for sourcing
#
# - We CAN use `local` and `local -r` if omit ksh
# - Keep minimum
# - aliases around `cd` is the typical use, because they should be alias or sourced shell function
# - Prefer `fname() {}` style: https://unix.stackexchange.com/a/73854
# - Do not add shebang and options. It means you shouldn't select `writeShellApplication` here
#
# NOTE: You should remember difference of bash and zsh for the arguments handling in completions
# https://rcmdnk.com/blog/2015/05/15/computer-linux-mac-zsh/

# Ensure absolute Nix path
# Use replaceVars to enable basic shellscript helpers such as shfmt, shuck, shellcheck or syntax highlighters
#
# Note: Using `replaceVars` directly avoids Import From Derivation (IFD) which was caused by the previous `builtins.readFile` + `writeText` wrapper.
replaceVars ./posix_shared_functions.bash {
  coreutils = lib.getBin pkgs.coreutils;
  diceware = lib.getExe pkgs.local.diceware;
  starship = "${pkgs.starship}";
}

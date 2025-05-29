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
pkgs.writeText "posix_shared_functions.sh" (
  # Actually this file is not a bash script, but dash mode is unuseful. Expecting mostly bash code will work even in zsh...
  # Ensure absolute Nix path even if coreutils for darwin
  # Use replaceVars to enable basic shellscript helpers such as shfmt, shellcheck and syntax highlighters
  builtins.readFile (
    replaceVars ./posix_shared_functions.bash {
      reponame = lib.getExe pkgs.my.reponame;
      ghqf = lib.getExe pkgs.my.ghqf;
      ghq = lib.getExe pkgs.ghq;
      gopass = lib.getExe pkgs.gopass;
      coreutils = lib.getBin pkgs.coreutils;
      fzf_bind_shell_hist = lib.getExe pkgs.my.fzf-bind-posix-shell-history-to-git-commit-message;
      starship = "${pkgs.starship}";
    }
  )
)

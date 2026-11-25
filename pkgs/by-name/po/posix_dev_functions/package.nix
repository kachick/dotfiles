{
  lib,
  pkgs,
  replaceVars,
  ...
}:
# Development-only POSIX shell functions separated from posix_shared_functions
# so essential/server profiles do not pull in git-x or history tools.
replaceVars ./posix_dev_functions.bash {
  git_x = lib.getExe pkgs.local.git-x;
}

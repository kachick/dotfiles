{
  lib,
  pkgs,
  replaceVars,
  ...
}:
# Development-only POSIX shell functions separated from posix_shared_functions
# so essential/server profiles do not pull in gitx, ghq, or history tools.
replaceVars ./posix_dev_functions.bash {
  gitx = lib.getExe pkgs.local.gitx;
  ghq = lib.getExe pkgs.ghq;
}

{
  pkgs,
  lib,
  ...
}:

{
  home = {
    sessionVariables = {
      # ref: https://github.com/boxdot/gurk-rs/pull/421
      GURK_PASSPHRASE_COMMAND = "${lib.getExe pkgs.gopass} show gurk-rs";
    };

    packages = with pkgs; [
      unstable.gurk-rs
    ];
  };
}

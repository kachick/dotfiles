{
  pkgs,
  lib,
  ...
}:

{
  home = {
    sessionVariables = {
      # Don't add needless quotation in the arguments. For example `gopass show 'rclone'` does not work. It should be `gopass show rclone`.
      RCLONE_PASSWORD_COMMAND = "${lib.getExe pkgs.gopass} show rclone";
    };

    packages =
      (with pkgs; [
        unstable.rclone
      ])
      ++ (with pkgs.local; [
        rclone-list-mounted
        rclone-mount
        rclone-fzf
        filen-cli-rs
      ]);
  };
}

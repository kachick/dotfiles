{
  writeShellApplication,
  pkgs,
  ...
}:

writeShellApplication {
  name = "filen-rclone";
  # Config path must be non-default.
  # When upstream rclone reads this configuration, it often corrupts or deletes the 'filen' entry.
  # This risk is mutual: filen-rclone may also corrupt or delete upstream rclone entries.
  #
  # We can NOT use RCLONE_CONFIG_DIR for this purpose. It appears existence for subprocess under rclone. Not for rclone itself
  # https://github.com/rclone/rclone/blob/1903b4c1a27e4810b2fe2d75c89c06bd17bb34ac/fs/config/config.go#L362-L364
  text = ''
    rclone --config "$XDG_CONFIG_HOME/filen-rclone/rclone.conf" "$@"
  '';
  runtimeInputs = [
    pkgs.my.filen-rclone-unwrapped
  ];

  meta = {
    description = "Ensure filen-rclone specific path and specific bin names";
  };
}

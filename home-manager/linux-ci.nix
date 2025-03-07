{
  pkgs,
  ...
}:

# This file is provided for CI use.
# Especially for unstable and heavy building packages for NixOS desktop.
# I don't need them on my container, however not checking in CI often crushes my desktop experience.
# So ensure the CI result before merging updates.
# Providing since GH-1085. It migtht be superseded by GH-642.

{
  home = {
    packages = with pkgs.unstable; [
      zed-editor

      quickemu
      quickgui
    ];
  };
}

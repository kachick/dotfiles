{
  pkgs,
  ...
}:

# This file is provided for CI use.
# Especially for unstable and heavy building packages for NixOS desktop.
# I don't need them on my container, however not checking in CI often crushes my desktop experience.
# So ensure the CI result before merging updates.
# Providing since GH-1085. It migtht be superseded by GH-642.
#
# Limitation: Don't add unfree packages such as cloudflare-warp, vscode

{
  home = {
    packages =
      (with pkgs.unstable; [
        # Disabling zed-editor because of it is most flaky in unstable channels.
        # If you want to use newer versions, consider to use upstream providing binary cache
        # See https://github.com/zed-industries/zed/issues/19937 for detail
        ## zed-editor

        typos-lsp
        dprint
        # gnome-boxes # Omitting. I believe it is a core package of NixOS.
      ])
      # Test builds and push the binary cache from CI
      # Consider to use ci-nix instead
      # Don't use `with` to keep indentation even if empty list
      ++ [
        # pkgs.patched.pname
        # pkgs.patched.lima # Enable when patched
      ]
      # These packages are override original pname instead of adding new namespace. So required to build the binary cache here. I'm unsure how to run these in ci-nix
      ++ [
        pkgs.gnome-keyring
        (with pkgs.ibus-engines; [ mozc ])
      ];
  };
}

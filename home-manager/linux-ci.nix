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
#
# Omit if:
#   - Which is build on ci-nix workflow: typos, dprint
#   - Which is NixOS core: gnome-*

{
  imports = [ ./lima-host.nix ];

  home = {
    packages =
      # (with pkgs.unstable; [
      #   # Disabling zed-editor because it was very flaky in unstable channel.
      #   # By the way, upstream's cache https://github.com/zed-industries/zed/issues/19937 is for nightly use.
      #   # It does not ensure providing cache for tagged versions.
      #   ## zed-editor
      # ]) ++

      # Test builds and push the binary cache from CI
      # Consider to use ci-nix instead
      # Don't use `with` to keep indentation even if empty list
      [
        # pkgs.patched.pname
      ]
      # These packages are override original pname instead of adding new namespace. So required to build the binary cache here. I'm unsure how to run these in ci-nix
      # ++ [
      #   # I don't know why this overriding will not work :<
      #   pkgs.gnome-keyring
      # ]
      ++ [ pkgs.gnome-shell ] # See overlays/default.nix
      ++ (with pkgs.ibus-engines; [ mozc ]);
  };
}

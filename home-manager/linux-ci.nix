{
  pkgs,
  inputs,
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
      ++ (with pkgs.patched; [
        lima
        signal-desktop
        shogihome
      ])
      ++ [
        # Only available on NixOS desktop. Making the binary cache here.
        inputs.flare-signal.${pkgs.stdenv.hostPlatform.system}.packages.default
      ];
  };
}

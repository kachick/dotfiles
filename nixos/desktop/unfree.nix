{ pkgs, ... }:

{
  # If adding unstable packages here, you should also add it into home-manager/linux-ci.nix
  environment.systemPackages = with pkgs; [
    ## Unfree packages

    # Don't use unstable channel as possible. It frequently backported to stable channel
    # ref: https://github.com/NixOS/nixpkgs/commits/nixos-25.11/pkgs/applications/editors/vscode/vscode.nix
    #
    # AFAIK, vscode still requires `commandLineArgs` to specify custom flags. It didn't respect ~/.config/electron-flags.conf likely other electron apps
    # This restriction might be related to
    #   - https://github.com/archlinux/svntogit-community/commit/f9ec89f9e2845e90f9524b28b74daf33ceb699bb
    #   - https://github.com/archlinux/svntogit-community/commit/c8bf3ae2e3deab793cb8e8544250ef943d14c85e
    (
      (vscode.override {
        # https://wiki.archlinux.org/title/Wayland#Electron
        # https://github.com/NixOS/nixpkgs/blob/3f8b7310913d9e4805b7e20b2beabb27e333b31f/pkgs/applications/editors/vscode/generic.nix#L207-L214
        commandLineArgs = [
          "--wayland-text-input-version=3"
          # https://github.com/microsoft/vscode/blob/5655a12f6af53c80ac9a3ad085677d6724761cab/src/vs/platform/encryption/common/encryptionService.ts#L28-L71
          # https://github.com/microsoft/vscode/blob/5655a12f6af53c80ac9a3ad085677d6724761cab/src/main.ts#L244-L253
          "--password-store=gnome-libsecret" # Required for GitHub Authentication. For example gnome-keyring, kwallet5, KeepassXC, pass-secret-service
        ];
      }).overrideAttrs
      (prevAttrs: {
        # https://incipe.dev/blog/post/using-visual-studio-code-insiders-under-home-manager/#an-os-keyring-couldnt-be-identified-for-storing-the-encryption-related-data-in-your-current-desktop-environment
        runtimeDependencies = prevAttrs.runtimeDependencies ++ [ pkgs.libsecret ];
      })
    )

    # NOTE: Google might extract chrome from themself with `Antitrust` penalties
    #       https://edition.cnn.com/2024/11/20/business/google-sell-chrome-justice-department/
    #
    # Don't use chromium, it does not provide built-in cloud translations
    #
    # Don't use unstable channel. It frequently backported to stable channel
    #  - https://github.com/NixOS/nixpkgs/commits/nixos-25.11/pkgs/by-name/go/google-chrome/package.nix
    #  - Actually unstable is/was broken. See GH-776
    #
    # if you changed hostname and chrome doesn't run, see https://askubuntu.com/questions/476918/google-chrome-wont-start-after-changing-hostname
    # `rm -rf ~/.config/google-chrome/Singleton*`
    #
    google-chrome

    local.chrome-with-profile-by-name
  ];

  nixpkgs.allowedUnfreePackageNames = [
    "google-chrome"
    "vscode"
  ];
}

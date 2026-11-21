{
  pkgs,
  ...
}:

{
  # If adding unstable packages here, you should also add it into home-manager/linux-ci.nix
  environment.systemPackages = with pkgs; [
    ## Unfree packages

    # Use unstable for vscode.
    # It is a repackaged binary without cache on cache.nixos.org (unfree).
    # Unstable keeps up with upstream changes and avoids broken backports on stable.
    #
    # Unset NIXOS_OZONE_WL for vscode to avoid CLI unknown-option warnings from
    # nixpkgs generic.nix flags. Electron 38+ defaults to Wayland auto-detection
    # and Chromium enables Wayland text-input-v3 by default (since 2025-04).
    (symlinkJoin {
      name = "vscode-${vscode.version}";
      paths = [ vscode ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/code --unset NIXOS_OZONE_WL
      '';
    })

    # NOTE: Google might extract chrome from themself with `Antitrust` penalties
    #       https://edition.cnn.com/2024/11/20/business/google-sell-chrome-justice-department/
    #
    # Don't use chromium, it does not provide built-in cloud translations
    #
    # Don't use unstable channel. It frequently backported to stable channel
    #  - https://github.com/NixOS/nixpkgs/commits/nixos-26.05/pkgs/by-name/go/google-chrome/package.nix
    #  - Actually unstable is/was broken. See GH-776
    #
    # if you changed hostname and chrome doesn't run, see https://askubuntu.com/questions/476918/google-chrome-wont-start-after-changing-hostname
    # `rm -rf ~/.config/google-chrome/Singleton*`
    #
    google-chrome

    local.antigravity-cli
    local.antigravity-hub
  ];

  nixpkgs.allowedUnfreePackageNames = [
    "google-chrome"
    "vscode"
    "antigravity-cli"
    "antigravity-hub"
  ];
}

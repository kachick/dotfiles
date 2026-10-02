{
  pkgs,
  ...
}:

{
  # If adding unstable packages here, you should also add it into home-manager/linux-ci.nix
  environment.systemPackages = with pkgs; [
    ## Unfree packages

    # Don't use unstable channel as possible. It frequently backported to stable channel
    # ref: https://github.com/NixOS/nixpkgs/commits/nixos-26.05/pkgs/applications/editors/vscode/vscode.nix
    #
    # See ./config/vscode/NOTE.md for Wayland flags, IME, and argv.json background
    vscode

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
  ];

  nixpkgs.allowedUnfreePackageNames = [
    "google-chrome"
    "vscode"
    "antigravity-cli"
  ];
}

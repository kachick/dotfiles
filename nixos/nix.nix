# https://github.com/NixOS/nixpkgs/blob/nixos-26.05/nixos/modules/config/nix.nix
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # `trusted-users = root` by default on NixOS 26.05
      # Setting another helps us to use binary cache substituters in flake.nix
      # Only using `--accept-flake-config` is not enough
      trusted-users = [
        "root"
        "@wheel"
      ];

      # Enabled by default on https://github.com/DeterminateSystems/nix-installer/releases/tag/v3.8.5
      # Therefore enable also on NixOS to keep consistency against other Linux distros
      # See https://github.com/NixOS/nix/pull/8047 for background
      always-allow-substitutes = true;

      extra-trusted-substituters = [
        "https://nix-community.cachix.org" # https://nix-community.org/cache/
        "https://cache.numtide.com" # Replaced from https://numtide.cachix.org: https://github.com/numtide/treefmt/pull/655
        "https://selfup.cachix.org" # GH-1235
        "https://kachick-dotfiles.cachix.org"
      ];

      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        "selfup.cachix.org-1:eY2eEd955BmRI7SultbRIV81vApqpJixunkV3XlXuT8="
        "kachick-dotfiles.cachix.org-1:XhiP3JOkqNFGludaN+/send30shcrn1UMDeRL9XttkI="
      ];

      accept-flake-config = true;
      # Enabling might cause heavy build time: https://github.com/NixOS/nix/issues/6033#issuecomment-1028697508
      # auto-optimise-store = true;

      # Workaround for https://github.com/NixOS/nix/issues/11728
      download-buffer-size =
        let
          GiB = 1024 * 1024 * 1024;
        in
        1 * GiB;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };

    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
  };
}

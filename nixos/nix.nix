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

      extra-substituters = [
        "https://cache.kachick.dev"
        "https://kachick.cachix.org"
      ];

      extra-trusted-substituters = [
        "https://nix-community.cachix.org" # https://nix-community.org/cache/
        "https://cache.numtide.com" # Replaced from https://numtide.cachix.org
      ];

      extra-trusted-public-keys = [
        "cache.kachick.dev-1:qxT+mjqH5A1VvQ/piD14E7heonmzkIPvati+dndwYFY="
        "kachick.cachix.org-1:7giZGKW03gPFkbde09JNpDKCbDGGwBuU/Z11W/jUtEQ="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];

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

  # Throttle disk I/O to avoid freezing desktop operations during weekly store optimization.
  #
  # Why not rely on upstream IOSchedulingClass=idle?
  # Upstream nix-optimise service sets IOSchedulingClass=idle.
  # However, modern NVMe devices with blk-mq ignore ionice CFQ classes under kyber or none schedulers.
  #
  # Why cgroup v2 bandwidth limits?
  # IOReadBandwidthMax and IOWriteBandwidthMax enforce cgroup v2 io.max limits
  # regardless of the underlying I/O scheduler.
  #
  # Why 150M read and 50M write?
  # Fast NVMe drives reach thousands of MB/s. Capping optimise to 150MB/s read and 50MB/s write
  # leaves plenty of I/O headroom for desktop apps and page fault handling.
  systemd.services.nix-optimise.serviceConfig = {
    IOReadBandwidthMax = "/ 150M";
    IOWriteBandwidthMax = "/ 50M";
    IOWeight = 10;
  };
}

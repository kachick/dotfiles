{ unstable, fetchpatch2, ... }:
unstable.rclone.overrideAttrs (
  finalAttrs: _previousAttrs: {
    # Remove these patches once 1.73.1 is available
    patches = [
      # Pre-release patch for Filen.io: https://github.com/rclone/rclone/pull/9145
      (fetchpatch2 {
        name = "fix-32-bit-targets-not-being-able-to-list-directories";
        url = "https://github.com/rclone/rclone/commit/ed5bd327c08bb222e1ab3888bb0869c76e3be629.patch?full_index=1";
        hash = "sha256-PzfjnGRG0Gpuggb62H6/W4H4HH0DlZ2XE9f7wLuuJgE=";
      })

      # Pre-release patch for Filen.io: https://github.com/rclone/rclone/pull/9140
      (fetchpatch2 {
        name = "fix-potential-panic-in-case-of-error-during-upload.patch";
        url = "https://github.com/rclone/rclone/commit/88b484722a3fb7ff2a7bf7af16d00647b27fd421.patch?full_index=1";
        hash = "sha256-DYmYPlqm5IhHDjWLaBNRW6nafPk8sJSp5taLa1P/7m8=";
      })
    ];

    vendorHash = "sha256-7x+3/0u4a0S8wN17u1YFECF2/ATDYh4Byu11RUXz8VM=";

    # nixpkgs definition is still using rec, so I should override at here until using finalAttrs
    # https://github.com/NixOS/nixpkgs/blob/ac7c30e2ca1f70e82222e1d95a0221c1edee9228/pkgs/by-name/rc/rclone/package.nix#L18
    ldflags = [
      "-s"
      "-w"
      "-X github.com/rclone/rclone/fs.Version=${finalAttrs.version}"
    ];
  }
)

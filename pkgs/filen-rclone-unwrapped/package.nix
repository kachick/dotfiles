{
  pkgs,
  fetchFromGitHub,
  ...
}:

# Don't install both rclone and this forked rclone together. They have same bin names with different logics. (And the different config schema!)
# Even if changed the priority, it makes confusing.
# And I don't prefer filen-rclone for other purpose for the stability.
# Prefer official rclone for non filen providers
pkgs.rclone.overrideAttrs (
  finalAttrs: previousAttrs: {
    pname = "filen-rclone-unwrapped";
    # MUST NOT use 1.70.0-filen.11 or older
    # They lacks the crucial patch https://github.com/FilenCloudDienste/filen-sdk-go/commit/cd9f4e00f07adf815d17ff1125751c943160f9f3
    version = "1.70.0-filen.15";

    src = fetchFromGitHub {
      owner = "FilenCloudDienste";
      repo = "filen-rclone";
      tag = "v${finalAttrs.version}";
      hash = "sha256-1EqtjBU0GV3+zhOYBQGtfFNox0xI+6uuMITWxz/wlyM=";
    };

    vendorHash = "sha256-GVbec1V8hejhNekCPJ808i23qkDZOvNI4xneEFVZKTI=";

    # nixpkgs definition is still using rec, so I should override at here until using finalAttrs
    # https://github.com/NixOS/nixpkgs/blob/480f847ddc3ccab43a76f31f713653b5ad79ba3f/pkgs/by-name/rc/rclone/package.nix#L18
    ldflags = [
      "-s"
      "-w"
      "-X github.com/rclone/rclone/fs.Version=${finalAttrs.version}"
    ];

    meta.priority = 10; # 5 by default. Prefer original rclone if exist (I don't think that case is none. However want to ensure it...)
  }
)

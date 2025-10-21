{
  rclone,
  fetchFromGitHub,
  ...
}:

# Don't install both rclone and this forked rclone together. They have same bin names with different logics. (And the different config schema!)
# Even if changed the priority, it makes confusing.
# And I don't prefer filen-rclone for other purpose for the stability.
# Prefer official rclone for non filen providers
rclone.overrideAttrs (
  finalAttrs: previousAttrs: {
    pname = "filen-rclone-unwrapped";
    # MUST NOT use 1.70.0-filen.11 or older
    # They lacks the crucial patch https://github.com/FilenCloudDienste/filen-sdk-go/commit/cd9f4e00f07adf815d17ff1125751c943160f9f3
    version = "1.70.0-filen.12";

    src = fetchFromGitHub {
      owner = "FilenCloudDienste";
      repo = "filen-rclone";
      tag = "v${finalAttrs.version}";
      hash = "sha256-YJtHGPSYEPAvthKr5eFFMqKaoEGw1DX3YwxXqe8/ckI=";
    };

    vendorHash = "sha256-5kzR9sREORBHolQgXpo/1CeITwel7GOczSYZCVl/SwA=";

    # nixpkgs definition is still using rec, so I should override at here until using finalAttrs
    # https://github.com/NixOS/nixpkgs/blob/9dcdad5caa134e3afa15401b40dd01391a636962/pkgs/applications/networking/sync/rclone/default.nix#L28
    ldflags = [
      "-s"
      "-w"
      "-X github.com/rclone/rclone/fs.Version=${finalAttrs.version}"
    ];

    meta.priority = 10; # 5 by default. Prefer original rclone if exist (I don't think that case is none. However want to ensure it...)
  }
)

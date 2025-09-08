{
  rclone,
  fetchFromGitHub,
  ...
}:
rclone.overrideAttrs (
  finalAttrs: previousAttrs: {
    pname = "filen-rclone";
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
  }
)

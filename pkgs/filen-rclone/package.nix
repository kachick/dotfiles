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

    dontVersionCheck = true; # The suffix `-filen.n` blocks to test
  }
)

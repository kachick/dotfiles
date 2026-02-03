{
  pkgs,
  fetchFromGitHub,
  fetchpatch2,
  ...
}:

# Don't install both rclone and this forked rclone together. They had same bin names with different logics. (And the different config schema!)
# Even if changed the priority, it makes confusing.
# And I don't prefer filen-rclone for other purpose for the stability.
# Prefer official rclone package for non filen providers
pkgs.unstable.rclone.overrideAttrs (
  finalAttrs: previousAttrs: {
    pname = "filen-rclone-unwrapped";
    # MUST NOT use FilenCloudDienste/filen-rclone's 1.70.0-filen.11 or older
    # They lacks the crucial patch https://github.com/FilenCloudDienste/filen-sdk-go/commit/cd9f4e00f07adf815d17ff1125751c943160f9f3
    version = "1.73.0";

    # Since 1.73.0, official rclone merged filen-rclone
    # It is frequently updated rather than FilenCloudDienste/filen-rclone
    # However it is not yet mergd in nixpkgs: https://github.com/NixOS/nixpkgs/pull/485515
    src = fetchFromGitHub {
      owner = "rclone";
      repo = "rclone";
      tag = "v${finalAttrs.version}";
      hash = "sha256-g/ofD/KsUOXVTOveHKddPN9PP5bx7HWFPct1IhJDZYE=";
    };

    patches = [
      # Unmerged patch for: https://github.com/FilenCloudDienste/filen-rclone/issues/5
      (fetchpatch2 {
        name = "fix-potential-panic-in-case-of-error-during-upload.patch";
        url = "https://patch-diff.githubusercontent.com/raw/rclone/rclone/pull/9140.patch?full_index=1";
        hash = "sha256-7hz6C+EExdBctHD/8X9Fn8MBeERfgVEtORBb1Zr7DTg=";
      })
    ];

    vendorHash = "sha256-LomeLlk0d/HTL0NKmbd083u7BHsy4FmAah9IzvmtO2s=";

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

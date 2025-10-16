{
  writeShellApplication,
  rclone,
  fetchFromGitHub,
  ...
}:

let
  # Don't install both rclone and this forked rclone together. They have same bin names with different logics. (And the different config schema!)
  # Even if changed the priority, it makes confusing.
  # And I don't prefer filen-rclone for other purpose for the stability.
  # Prefer official rclone for non filen providers
  forked-rclone = rclone.overrideAttrs (
    finalAttrs: previousAttrs: {
      pname = "filen-rclone";
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
  );
in
writeShellApplication {
  name = "filen-rclone";
  # Config path must be non-default.
  # When upstream rclone reads this configuration, it often corrupts or deletes the 'filen' entry.
  # This risk is mutual: filen-rclone may also corrupt or delete upstream rclone entries.
  #
  # We can NOT use RCLONE_CONFIG_DIR for this purpose. It appears existence for subprocess under rclone. Not for rclone itself
  # https://github.com/rclone/rclone/blob/1903b4c1a27e4810b2fe2d75c89c06bd17bb34ac/fs/config/config.go#L362-L364
  text = ''
    rclone --config "$XDG_CONFIG_HOME/filen-rclone/rclone.conf" "$@"
  '';
  runtimeInputs = [
    forked-rclone
  ];
  meta = {
    description = "Ensure filen-rclone specific path and specific bin names";
  };
}

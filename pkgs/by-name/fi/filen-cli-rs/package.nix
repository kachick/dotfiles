{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  sqlite,
  openssl,
  zstd,
  versionCheckHook,
  nix-update-script,
}:

# This package is a personal fork of https://github.com/NixOS/nixpkgs/pull/563557

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "filen-cli-rs";
  version = "0.3.0";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "FilenCloudDienste";
    repo = "filen-rs";
    tag = "filen-cli@v${finalAttrs.version}";
    hash = "sha256-y2Xlbx5/TdEpJTpXjD7hjvHKwJUe7c1x0q9Iosnz55M=";
  };

  cargoHash = "sha256-vqtHZ7TQt3vCp4suQg915mmG2vbhPstdyLRDPm9vTnY=";

  buildAndTestSubdir = "filen-cli";

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    sqlite # libsqlite3-sys
    openssl # openssl-sys
    zstd # zstd-sys
  ];

  env = {
    # Enable nightly features for higher-ranked-assumptions:
    # https://github.com/FilenCloudDienste/filen-rs/blob/29eb4bcd797229958dc0ef6ab12d9a8f8424b200/rust-toolchain.toml#L2
    RUSTC_BOOTSTRAP = true;

    # Upstream configures development-focused linker in .cargo/config.toml, but drops them in CD:
    # https://github.com/FilenCloudDienste/filen-rs/commit/29eb4bcd797229958dc0ef6ab12d9a8f8424b200
    RUSTFLAGS = "-Zhigher-ranked-assumptions";
  };

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  doInstallCheck = true;

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        # nix-update does not pass --flake to child scripts: https://github.com/Mic92/nix-update/pull/330
        "--flake"
        # Prefer filen-cli-releases over filen-rs to get the version.
        # - filen-rs is a monorepo with too many other tags (filen-js@*) that hide the target tags (filen-cli@v*).
        #   We can revisit once https://github.com/Mic92/nix-update/issues/231 is resolved.
        # - filen-cli-releases often keeps new tags marked as pre-release after filen-rs releases, likely for real-world testing.
        "--url"
        "https://github.com/FilenCloudDienste/filen-cli-releases"
        "--use-github-releases"
      ];
    };
  };

  meta = {
    description = "Tools for interacting with Filen cloud drive";
    homepage = "https://github.com/FilenCloudDienste/filen-rs";
    changelog = "https://github.com/FilenCloudDienste/filen-rs/blob/filen-cli@v${finalAttrs.version}/filen-cli/CHANGELOG.md";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [
      kachick
    ];
    mainProgram = "filen-cli";
    platforms = with lib.platforms; unix ++ windows;
  };
})

{
  lib,
  fetchFromGitHub,
  pkgs,
  versionCheckHook,
  nix-update-script,
}:

# This package is a personal fork of https://github.com/NixOS/nixpkgs/pull/563557

let
  # Use latest rustPlatform to make the upstream PR up-to-date easier
  inherit (pkgs.unstable) rustPlatform;
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "filen-cli-rs";
  version = "0.2.9";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "FilenCloudDienste";
    repo = "filen-rs";
    tag = "filen-cli@v${finalAttrs.version}";
    hash = "sha256-OIqutQawSjowKp08A2pbsSLxHOmPESEWHi3Y/E2v0/Q=";
  };

  cargoHash = "sha256-PNRj89hYOcBw1CsqWVn/HXtTQuz/afQq7ZwCzG7a16o=";

  buildAndTestSubdir = "filen-cli";

  env = {
    # Enable nightly features for higher-ranked-assumptions:
    # https://github.com/FilenCloudDienste/filen-rs/blob/29eb4bcd797229958dc0ef6ab12d9a8f8424b200/rust-toolchain.toml#L2
    RUSTC_BOOTSTRAP = true;

    # Upstream configures development-focused linker in .cargo/config.toml, but drops them in CD:
    # https://github.com/FilenCloudDienste/filen-rs/commit/29eb4bcd797229958dc0ef6ab12d9a8f8424b200
    RUSTFLAGS = "-Zhigher-ranked-assumptions";
  };

  cargoTestFlags = [
    # Avoid tests under filen-cli/tests/ that require a real account
    "--lib"
  ];

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

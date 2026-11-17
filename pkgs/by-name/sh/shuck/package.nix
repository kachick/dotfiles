{
  lib,
  fetchFromGitHub,
  rustPlatform,
  stdenv,
  versionCheckHook,
  nix-update-script,
}:

# This package is a personal fork of https://github.com/NixOS/nixpkgs/pull/564243 because it is unmerged

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "shuck";
  version = "0.2.7";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "ewhauser";
    repo = "shuck";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Nz2Zlkz7tqehRP6L1mLYl+Fpoq8qxs43h/vw6tUesc0=";
  };

  cargoHash = "sha256-tqhjMlrQbkg8nnh7WkQJ+3KBCqqSUi2xh9hms++HcOQ=";

  cargoBuildFlags = [
    "--package"
    "shuck-cli"
  ];

  cargoTestFlags = [
    "--package"
    "shuck-cli"
  ];

  checkFlags = lib.optionals stdenv.hostPlatform.isDarwin [
    # Watch-mode test is timing sensitive and fails in the sandbox
    "--skip"
    "check_watch_reruns_when_files_change"
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
        "--use-github-releases"
      ];
    };
  };

  meta = {
    description = "Shell script linter, formatter, and language server";
    downloadPage = "https://github.com/ewhauser/shuck";
    homepage = "https://ewhauser.github.io/shuck/";
    changelog = "https://github.com/ewhauser/shuck/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      kachick
    ];
    mainProgram = "shuck";
    platforms = with lib.platforms; unix ++ windows;
  };
})

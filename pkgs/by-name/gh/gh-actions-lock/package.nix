{
  lib,
  pkgs,
  fetchFromGitHub,
  nix-update-script,
}:

# This is a personal fork of https://github.com/NixOS/nixpkgs/pull/568617

let
  # Different Go version between nixpkgs, it uses 1.26, however I standardize to 1.27 in this repo
  inherit (pkgs.unstable) buildGo127Module;
in
buildGo127Module (finalAttrs: {
  pname = "gh-actions-lock";
  version = "0.1.6";

  __structuredAttrs = true;

  src = fetchFromGitHub {
    owner = "github";
    repo = "gh-actions-lock";
    tag = "v${finalAttrs.version}";
    hash = "sha256-OqxkuQPM0JwhTLWUgeNdaMRDj2uuAX/dGEDyanJV8iY=";
  };

  vendorHash = "sha256-AYrg81SYC2JBpRZgG8O9R5ymCAsX8hsipwoSS1mP/Uc=";

  ldflags = [
    "-s"
  ];

  env.CGO_ENABLED = "0";

  # Avoid versionCheckHook because displaying the version requires the gh command.
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/${finalAttrs.meta.mainProgram}" --help
    runHook postInstallCheck
  '';
  doInstallCheck = true;

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--use-github-releases"
        "--version-regex=^v([0-9.]+)$"
      ];
    };
  };

  meta = {
    description = "GitHub CLI extension to lock workflow dependencies";
    homepage = "https://github.com/github/gh-actions-lock";
    changelog = "https://github.com/github/gh-actions-lock/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      kachick
    ];
    mainProgram = "gh-actions-lock";
  };
})

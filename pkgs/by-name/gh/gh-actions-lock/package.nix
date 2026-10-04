{
  lib,
  pkgs,
  fetchFromGitHub,
  fetchpatch2,
  versionCheckHook,
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

  # debug.ReadBuildInfo does not provide version information in buildGoModule.
  # Keep the upstream "v" prefix format because the "--json" includes it.
  postPatch = ''
    substituteInPlace cmd/gh-actions-lock/run.go \
      --replace-fail 'return info.Main.Version' 'return "v${finalAttrs.version}"'
  '';

  patches = [
    (fetchpatch2 {
      name = "add-version-flag.patch";
      url = "https://patch-diff.githubusercontent.com/raw/github/gh-actions-lock/pull/135.patch?full_index=1";
      hash = "sha256-LbNkIY5NOfM37G6n59wE9kgCJh1BhfR+bMUTeK0tW5g=";
    })
  ];

  vendorHash = "sha256-AYrg81SYC2JBpRZgG8O9R5ymCAsX8hsipwoSS1mP/Uc=";

  ldflags = [
    "-s"
  ];

  env.CGO_ENABLED = "0";

  # Workaround for: panic: httptest: failed to listen on a port: listen tcp6 [::1]:0: bind: operation not permitted
  # ref: https://github.com/NixOS/nix/pull/1646
  __darwinAllowLocalNetworking = true;

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
    platforms = with lib.platforms; unix ++ windows;
  };
})

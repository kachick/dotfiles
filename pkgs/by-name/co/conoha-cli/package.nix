{
  lib,
  stdenv,
  pkgs,
  fetchFromGitHub,
  installShellFiles,
  gitMinimal,
  versionCheckHook,
  nix-update-script,
}:

let
  inherit (pkgs.unstable) buildGo126Module;
in
buildGo126Module (finalAttrs: {
  pname = "conoha-cli";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "crowdy";
    repo = "conoha-cli";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9fM2IFFaZ4n5NtruFUHLvICr0ujzsUe9SPAA8F2r/4g=";
  };

  vendorHash = "sha256-GGJhFBVuQcdd3LveztEZu26h+1BCyMZee0uBIQGxJUE=";

  ldflags = [
    "-s"
    "-X=github.com/crowdy/conoha-cli/cmd.version=${finalAttrs.version}"
  ];

  subPackages = [
    "."
  ];

  nativeBuildInputs = [
    installShellFiles
  ];

  env = {
    CGO_ENABLED = "0";
  };

  nativeCheckInputs = [
    gitMinimal
  ];

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd conoha-cli \
      --bash <("$out/bin/conoha-cli" completion bash) \
      --fish <("$out/bin/conoha-cli" completion fish) \
      --zsh <("$out/bin/conoha-cli" completion zsh)
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  doInstallCheck = true;

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [
        "--use-github-releases"
      ];
    };
  };

  meta = {
    homepage = "https://github.com/crowdy/conoha-cli";
    description = "ConoHa VPS3 CLI";
    changelog = "https://github.com/crowdy/conoha-cli/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "conoha-cli";

    maintainers = with lib.maintainers; [
      kachick
    ];
  };
})

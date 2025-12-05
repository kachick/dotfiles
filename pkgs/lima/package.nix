# The lima package always takes long time to be reviewed and merged. So I can't depend on nixpkgs's binary cache
#
# Current status in nixpkgs: Wait for merging https://github.com/NixOS/nixpkgs/pull/461178
# - 1.2.2 or higher is required to avoid some CVEs in the nerdctl dependency: https://github.com/NixOS/nixpkgs/pull/459093
# - 2.0.0 includes patch for `limactl stop`: https://github.com/lima-vm/lima/pull/4303
# - 2.0.1 includes patch for graceful shutdown: https://github.com/lima-vm/lima/pull/4310

{
  lib,
  stdenv,
  pkgs,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  qemu,
  darwin,
  makeWrapper,
  nix-update-script,
  apple-sdk_15, # Use 15 over 26 to consider GHA. macos-15-intel is the last x86_64-darwin runner for GitHub Actions.
  writableTmpDirAsHomeHook,
  versionCheckHook,
  testers,
  writeText,
  runCommand,
  jq,
  _7zz,
  file,
  gnugrep,
}:

let
  inherit (pkgs.my) lima;
in
buildGoModule (finalAttrs: {
  pname = "lima";
  version = "2.0.2";

  src = fetchFromGitHub {
    owner = "lima-vm";
    repo = "lima";
    tag = "v${finalAttrs.version}";
    hash = "sha256-MWNvHHyf2qZxt83D22tTKR6EXAeAgcoXE1YjXHc9SwQ=";
  };

  vendorHash = "sha256-fCqAf0buqA6GajP7SIsVPyKM3jY2n9CbS5hpa3dsWbc=";

  nativeBuildInputs = [
    makeWrapper
    installShellFiles

    # For checkPhase, and installPhase(required to build completion)
    writableTmpDirAsHomeHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [ darwin.sigtool ];

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin [ apple-sdk_15 ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail 'codesign -f -v --entitlements vz.entitlements -s -' 'codesign -f --entitlements vz.entitlements -s -' \
      --replace-fail 'rm -rf _output vendor' 'rm -rf _output'
  '';

  # It attaches entitlements with codesign and strip removes those,
  # voiding the entitlements and making it non-operational.
  dontStrip = stdenv.hostPlatform.isDarwin;

  # Setting env.CGO_ENABLED does not work, because the upstream forces the value.
  #   - limactl: CGO_ENABLED=1
  #   - guest agents(include native-agent): CGO_ENABLED=0
  # See also passthru.tests

  buildPhase =
    let
      makeFlags = [
        "VERSION=v${finalAttrs.version}"
        "CC=${stdenv.cc.targetPrefix}cc"
      ];
    in
    ''
      runHook preBuild

      make ${lib.escapeShellArgs makeFlags} native

      runHook postBuild
    '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r _output/* $out
    wrapProgram $out/bin/limactl \
      --prefix PATH : ${lib.makeBinPath [ qemu ]}
  ''
  + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd limactl \
      --bash <($out/bin/limactl completion bash) \
      --fish <($out/bin/limactl completion fish) \
      --zsh <($out/bin/limactl completion zsh)
  ''
  + ''
    runHook postInstall
  '';

  nativeInstallCheckInputs = [
    # Workaround for: "panic: $HOME is not defined" at https://github.com/lima-vm/lima/blob/cb99e9f8d01ebb82d000c7912fcadcd87ec13ad5/pkg/limayaml/defaults.go#L53
    writableTmpDirAsHomeHook
    versionCheckHook
  ];
  doInstallCheck = true;
  versionCheckProgram = "${placeholder "out"}/bin/limactl";
  versionCheckProgramArg = "--version";
  versionCheckKeepEnvironment = [ "HOME" ];

  installCheckPhase = ''
    runHook preInstallCheck

    USER=nix $out/bin/limactl validate templates/default.yaml

    runHook postInstallCheck
  '';

  passthru = {
    tests =
      let
        arch = stdenv.hostPlatform.parsed.cpu.name;
      in
      {
        # `nix build .#lima.passthru.tests.minimalAgent`
        minimalAgent = testers.testEqualContents {
          assertion = "limactl only detects host's architecture guest agent by default";
          expected = writeText "expected" ''
            true
            1
          '';
          actual =
            runCommand "actual"
              {
                nativeBuildInputs = [
                  writableTmpDirAsHomeHook
                  lima
                  jq
                ];
              }
              ''
                limactl info | jq '.guestAgents | has("${arch}")' >>"$out"
                limactl info | jq '.guestAgents | length' >>"$out"
              '';
        };

        # Regression test for https://github.com/NixOS/nixpkgs/issues/456953.
        # See https://github.com/NixOS/nixpkgs/pull/461178#issuecomment-3551957460 for detail
        staticallyLinkedAgent =
          runCommand "${finalAttrs.pname}-guestagent-linked-test"
            {
              nativeBuildInputs = [
                lima
                _7zz
                # glibc
                file # Easier than `lld(glibc)` or `readelf`
                gnugrep
              ];
            }
            ''
              7zz x "${lima}/share/lima/lima-guestagent.Linux-${arch}.gz"
              file './lima-guestagent.Linux-${arch}' >"$out"
              grep -P 'ELF.+statically linked' "$out"
            '';
      };

    updateScript = nix-update-script {
      extraArgs = [
        "--override-filename"
        ./source.nix
      ];
    };
  };

  meta = {
    homepage = "https://github.com/lima-vm/lima";
    description = "Linux virtual machines with automatic file sharing and port forwarding";
    changelog = "https://github.com/lima-vm/lima/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [
      kachick
    ];
  };
})

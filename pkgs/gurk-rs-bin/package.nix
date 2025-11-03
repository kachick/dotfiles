{
  lib,
  stdenvNoCC,
  fetchzip,
  versionCheckHook,
  writeShellApplication,
  gh,
  gnugrep,
  common-updater-scripts,
}:

let
  version = "0.7.1";
  repo = "boxdot/gurk-rs";
  # See https://github.com/boxdot/gurk-rs/releases for latest
  # Musl versions are now a static-linked binary, so it works on NixOS out of the box.
  # https://github.com/boxdot/gurk-rs/issues/149#issuecomment-1294063051
  sources = {
    x86_64-linux = fetchzip {
      url = "https://github.com/${repo}/releases/download/v${version}/gurk-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-AuMmE97CexJoD7uKTSgwjbOC2mS6bsacZxXmB8xQEsg=";
    };

    aarch64-linux = fetchzip {
      url = "https://github.com/${repo}/releases/download/v${version}/gurk-aarch64-unknown-linux-musl.tar.gz";
      hash = "sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=";
    };

    x86_64-darwin = fetchzip {
      url = "https://github.com/${repo}/releases/download/v${version}/gurk-x86_64-apple-darwin.tar.gz";
      hash = "sha256-Js+m2A2ZRDAb08NUualcRDUqGN8rYWvJequ0lxOvAyo=";
    };

    aarch64-darwin = fetchzip {
      url = "https://github.com/${repo}/releases/download/v${version}/gurk-aarch64-apple-darwin.tar.gz";
      hash = "sha256-gFpRRGeJitctNhzr9EOJhzakyTrjkvmd8xT/dCE81ao=";
    };
  };
  mainProgram = "gurk";
  system = stdenvNoCC.hostPlatform.system;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gurk-rs-bin";
  inherit version;

  src = sources.${system} or (throw "Unsupported system: ${system}");

  buildPhase = ''
    mkdir -p "$out/bin"
  '';

  installPhase = ''
    ln -s "$src/${mainProgram}" "$out/bin/gurk"
  '';

  nativeInstallCheckInputs = [
    versionCheckHook
  ];
  doInstallCheck = true;
  # NOTE: Keep except on NixOS/nixpkgs/*-unstable. See https://github.com/NixOS/nixpkgs/pull/412768#issuecomment-3427141813
  versionCheckProgram = "${placeholder "out"}/bin/${mainProgram}";
  versionCheckProgramArg = "--version";

  passthru = {
    inherit sources;

    # NOTE: nix-update can not run this script until introducing: https://discourse.nixos.org/t/how-can-i-run-the-updatescript-of-personal-packages/25274/2
    # Test and the updating should be done in nixpkgs repository. I should maintain personal fork of https://github.com/kachick/nixpkgs/tree/init-gurk-rs-bin/pkgs/by-name/gu/gurk-rs-bin for this purpose
    updateScript = lib.getExe (writeShellApplication {
      name = "${finalAttrs.pname}-updater-script";

      runtimeInputs = [
        gh
        gnugrep
        common-updater-scripts
      ];

      text = ''
        new_version="$(
          gh release list --repo '${repo}' --limit 1 --json tagName --jq '.[] .tagName' | \
            grep --only-matching --perl-regexp '^v\K([0-9.]+)'
        )"

        for platform in ${lib.escapeShellArgs finalAttrs.meta.platforms}; do
          update-source-version '${finalAttrs.pname}' "$new_version" --ignore-same-version --source-key="sources.$platform"
        done
      '';
    });
  };

  meta = {
    inherit mainProgram;
    description = "Signal Messenger client for terminal";
    homepage = "https://github.com/${repo}";
    # TODO(kachick): Nixpkgs version bumps often fail because this package’s crate setup isn’t very standard.
    # I may address it again after merging https://github.com/NixOS/nixpkgs/pull/387337.
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
    ];
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [
      kachick
    ];
    # Don't relax this condition such as "unix", "linux", and "darwin". It depends on which assets are provided by upstream.
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    priority = 10; # 5 by default. Prefer src built if exist
  };
})

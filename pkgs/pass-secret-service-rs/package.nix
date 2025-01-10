{
  lib,
  fetchFromGitHub,
  rustPlatform,
  nix-update-script,
}:

rustPlatform.buildRustPackage rec {
  pname = "pass-secret-service-rs";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "grimsteel";
    repo = "pass-secret-service";
    tag = "v${version}";
    hash = "sha256-4NS/f7x4/GKrnvrhqDnjxTYF5Wd/7yj/hcpYl0l5Qjk=";
  };

  cargoHash = "sha256-6KJy2bKlG/7dCGLDCDV/ZmmP84MBamVDereDgcFwCoU=";

  postPatch = ''
    substituteInPlace 'systemd/org.freedesktop.secrets.service' \
      --replace-fail '/usr/bin' "$out/bin"
    substituteInPlace 'systemd/pass-secret-service.service' \
      --replace-fail '/usr/bin' "$out/bin"
  '';

  postInstall = ''
    install -Dm0644 'systemd/org.freedesktop.secrets.service' -t "$out/lib/systemd/user"
    install -Dm0644 'systemd/pass-secret-service.service' -t "$out/lib/systemd/user"
  '';

  # Can't use versionCheckHook, they does not provide the version printing flag

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = with lib; {
    description = "Implementation of org.freedesktop.secrets using `pass`";
    homepage = "https://github.com/grimsteel/pass-secret-service";
    changelog = "https://github.com/grimsteel/pass-secret-service/releases/tag/v${version}";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [
      kachick
    ];
    mainProgram = "pass-secret-service";
  };
}

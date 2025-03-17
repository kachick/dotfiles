{
  stdenvNoCC,
  gnused,
  installShellFiles,
  tailscale,
  ...
}:
stdenvNoCC.mkDerivation {
  # https://github.com/NixOS/nixpkgs/issues/23099#issuecomment-964024407
  dontUnpack = true;
  name = "tailscaled-service";
  postInstall = ''
    sed '/\[Service\]/a EnvironmentFile=/etc/default/tailscaled' <'${tailscale}/lib/systemd/system/tailscaled.service' > ./tailscaled.service
    install -D -m0444 -t $out/lib/systemd/system ./tailscaled.service
  '';
  nativeBuildInputs = [
    gnused
    installShellFiles
  ];
  meta = {
    description = ''
      Revert https://github.com/NixOS/nixpkgs/commit/503caab7765f31d18bce7fa58b26d447bc413c17#diff-be05f1b8ce13345e8991a5ee802268e588cc6f10fd4d5fcc62c6c1300bd97896R36 for non NixOS use
    '';
  };
}

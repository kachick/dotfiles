{
  lib,
  buildGoModule,
  makeWrapper,
  dix,
}:

buildGoModule {
  pname = "nix-diff";
  version = "0.0.1";

  src = ../../../cmd/nix-diff;

  # No external go dependencies other than standard library or internal packages
  vendorHash = null;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/nix-diff \
      --prefix PATH : ${lib.makeBinPath [ dix ]}
  '';

  meta = {
    description = "Compare nix derivations and report package changes";
    license = lib.licenses.mit;
    mainProgram = "nix-diff";
  };
}

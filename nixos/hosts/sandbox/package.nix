{
  pkgs,
  declaredRunner,
}:

pkgs.buildGo127Module {
  pname = "microvm-sandbox";
  version = "0.0.1";

  __structuredAttrs = true;

  nativeBuildInputs = [
    pkgs.makeWrapper
  ];

  vendorHash = null;

  src =
    with pkgs.lib.fileset;
    toSource {
      root = ../../..;
      fileset = unions [
        ../../../go.mod
        ../../../cmd/microvm-sandbox
      ];
    };

  subPackages = [
    "cmd/microvm-sandbox"
  ];

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
  ];

  postFixup = ''
    wrapProgram $out/bin/microvm-sandbox \
      --prefix PATH : "${
        pkgs.lib.makeBinPath [
          pkgs.fzf
          pkgs.gum
          pkgs.openssh
        ]
      }" \
      --set-default MICROVM_RUN "${declaredRunner}/bin/microvm-run"
  '';

  meta = {
    description = "Lifecycle CLI for the NixOS microvm sandbox";
    mainProgram = "microvm-sandbox";
  };
}

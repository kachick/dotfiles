{ pkgs, ... }:
pkgs.unstable.buildGo124Module (finalAttrs: {
  pname = "git-hooks-pre-push";
  version = "0.0.1";
  runtimeInputs = with pkgs; [
    git
    typos
    unstable.gitleaks
    my.run_local_hook
  ];
  vendorHash = "sha256-Y7DufJ0l+IZ/l2/LPmFRJevc+MCPqGxnESn7RWmSatg=";
  src = ./.;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X main.TyposConfigPath=${../../typos.toml}"
  ];

  meta = {
    description = "GH-540 and GH-699";
    mainProgram = finalAttrs.pname;
  };
})

{ pkgs, ... }:
pkgs.unstable.buildGo124Module (finalAttrs: {
  pname = "git-hooks-commit-msg";
  version = "0.0.1";
  runtimeInputs = with pkgs; [
    typos
    unstable.gitleaks
    my.run_local_hook
  ];
  vendorHash = null;
  src = ./.;

  env.CGO_ENABLED = 0;

  ldflags = [
    "-s"
    "-w"
    "-X main.TyposConfigPath=${../../typos.toml}"
  ];

  meta = {
    description = "Git hook for commit-msg. See GH-325";
    mainProgram = finalAttrs.pname;
  };
})

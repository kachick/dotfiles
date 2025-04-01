{
  pkgs,
  ...
}:
pkgs.unstable.buildGo124Module (finalAttrs: {
  pname = "run_local_hook";
  version = "0.0.1";

  # Don't add dependencies as possible to keep simple nix code.
  # For example, git should be because of this is a git hook

  vendorHash = null;
  src = ./.;

  env.CGO_ENABLED = 0;

  meta = {
    description = "GH-545. Run local git hook from global hook";
    mainProgram = finalAttrs.pname;
  };
})

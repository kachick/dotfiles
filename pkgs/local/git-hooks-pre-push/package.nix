{
  pkgs,
  lib,
  makeWrapper,
  ...
}:

pkgs.unstable.ocamlPackages.buildDunePackage {
  pname = "git_hooks_pre_push";
  version = "0.0.1";

  src = ../../../cmd-ocaml;

  nativeBuildInputs = [
    makeWrapper
  ];

  postFixup =
    let
      # Use lib.escapeShellArg if the path contains spaces, but here it is a nix store path.
      path = lib.makeBinPath (
        with pkgs;
        [
          gitMinimal
          unstable.typos
          unstable.betterleaks
          local.run_local_hook
        ]
      );
    in
    ''
      wrapProgram $out/bin/git_hooks_pre_push \
        --prefix PATH : "${path}" \
        --set TYPOS_CONFIG_PATH "${../../../typos.toml}"
    '';

  meta = {
    description = "GH-540 and GH-699 (OCaml port)";
    mainProgram = "git_hooks_pre_push";
  };
}

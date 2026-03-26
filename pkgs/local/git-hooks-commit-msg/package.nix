{
  pkgs,
  lib,
  makeWrapper,
  ...
}:

pkgs.unstable.ocamlPackages.buildDunePackage {
  pname = "git_hooks_commit_msg";
  version = "0.0.1";

  src = ../../../cmd-ocaml;

  nativeBuildInputs = [
    makeWrapper
  ];

  postFixup =
    let
      path = lib.makeBinPath (
        with pkgs;
        [
          unstable.typos
          unstable.betterleaks
          local.run_local_hook
        ]
      );
    in
    ''
      wrapProgram $out/bin/git_hooks_commit_msg \
        --prefix PATH : "${path}" \
        --set TYPOS_CONFIG_PATH "${../../../typos.toml}"
    '';

  meta = {
    description = "Git hook for commit-msg. See GH-325 (OCaml port)";
    mainProgram = "git_hooks_commit_msg";
  };
}

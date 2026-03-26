{
  pkgs,
  ...
}:

pkgs.unstable.ocamlPackages.buildDunePackage {
  pname = "run_local_hook";
  version = "0.0.1";

  src = ../../../cmd-ocaml;

  meta = {
    description = "GH-545. Run local git hook from global hook (OCaml port)";
    mainProgram = "run_local_hook";
  };
}

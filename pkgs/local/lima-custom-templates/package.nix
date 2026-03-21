{
  lib,
  stdenvNoCC,
  yq-go,
  pkgs,
}:

let
  lima = pkgs.local.lima;
in
stdenvNoCC.mkDerivation {
  pname = "lima-custom-templates";
  version = lima.version;

  dontUnpack = true;

  nativeBuildInputs = [ yq-go ];

  buildPhase = ''
    runHook preBuild

    yq 'del(.base[] | select(. == "template:_default/mounts"))' ${lima}/share/lima/templates/docker.yaml > homeless-docker.yaml

    runHook postBuild
  '';

  doCheck = true;

  checkPhase = ''
    runHook preCheck

    # Verify that the deletion actually happened by comparing the logical structure.
    # If the structure is exactly the same, the 'del' command silently failed (e.g. target string changed).
    if [ "$(yq -o=json -I=0 '.' ${lima}/share/lima/templates/docker.yaml)" = "$(yq -o=json -I=0 '.' homeless-docker.yaml)" ]; then
      echo "Error: The template was not modified. The target string might not exist anymore." >&2
      exit 1
    fi

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/lima/templates
    cp homeless-docker.yaml $out/share/lima/templates/

    runHook postInstall
  '';

  meta = {
    description = "Custom Lima templates with the default home mount removed";
    longDescription = ''
      Most standard Lima templates (except for a few like k3s) inherit `template:_default/mounts`, which cannot be excluded via `default.yaml`.
      To improve security, this package creates templates with those mounts removed by default.
      While Lima 2.0+ supports avoiding default mounts via CLI flags like `--mount-only`, it is safer to have them disabled by default in the template.
      Revisit once https://github.com/lima-vm/lima/discussions/4372 is resolved.
    '';
    inherit (lima.meta) platforms;
    maintainers = with lib.maintainers; [ kachick ];
  };
}

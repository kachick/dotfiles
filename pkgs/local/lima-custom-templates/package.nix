{
  lib,
  stdenvNoCC,
  yq-go,
  gnugrep,
  pkgs,
}:

let
  lima = pkgs.local.lima;
in
stdenvNoCC.mkDerivation {
  pname = "lima-custom-templates";
  version = lima.version;

  dontUnpack = true;

  nativeBuildInputs = [
    yq-go
    gnugrep
  ];

  buildPhase = ''
    runHook preBuild

    for template_path in ${lima}/share/lima/templates/*.yaml; do
      template_name=$(basename "$template_path")
      if yq '.base[] | select(. == "template:_default/mounts")' "$template_path" | grep -q .; then
        yq 'del(.base[] | select(. == "template:_default/mounts"))' "$template_path" > "homeless-$template_name"
      fi
    done

    runHook postBuild
  '';

  doCheck = true;

  checkPhase = ''
    runHook preCheck

    # Verify that the deletion actually happened for a representative template.
    if [ "$(yq -o=json -I=0 '.' ${lima}/share/lima/templates/docker.yaml)" = "$(yq -o=json -I=0 '.' homeless-docker.yaml)" ]; then
      echo "Error: The template was not modified. The target string might not exist anymore." >&2
      exit 1
    fi

    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/lima/templates
    cp homeless-*.yaml $out/share/lima/templates/

    runHook postInstall
  '';

  meta = {
    description = "Custom Lima templates with the default home mount removed";
    longDescription = ''
      Most standard Lima templates (except for a few like k3s) inherit `template:_default/mounts`, which cannot be excluded via `default.yaml`.
      To improve security, this package creates templates with those mounts removed by default.
      While Lima 2.1+ supports avoiding default mounts via CLI flags like `--mount-only`, `--mount-none` it is safer to have them disabled by default in the template.
      Revisit once https://github.com/lima-vm/lima/discussions/4372 is resolved.
    '';
    inherit (lima.meta) platforms;
    maintainers = with lib.maintainers; [ kachick ];
  };
}

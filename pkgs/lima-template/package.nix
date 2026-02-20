{
  runCommand,
  yq-go,
  lib,
  my,
}:

let
  inherit (my.lima) version;
  baseTemplate = "${my.lima}/share/lima/templates/docker.yaml";
  patchYaml = ../../config/lima/patch.yaml;
in
runCommand "lima-template"
  {
    nativeBuildInputs = [ yq-go ];
    meta = {
      description = "Generated Lima template with Docker and customized Nix/home-manager provisioning. Version follows my.lima package output";
      inherit version;
      license = lib.licenses.asl20;
    };
  }
  ''
    mkdir -p $out
    yq eval-all '
      select(fi==0) as $base |
      select(fi==1) as $patch |
      $base * $patch |
      .provision = $base.provision + $patch.provision |
      .mounts = $base.mounts + $patch.mounts
    ' "${baseTemplate}" "${patchYaml}" > "$out/lima.yaml"
  ''

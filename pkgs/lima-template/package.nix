{
  runCommand,
  fetchurl,
  yq-go,
  lib,
}:

let
  version = "2.0.3"; # selfup {"extract":"v?\\d\\.\\d+\\.\\d+","replacer":["limactl", "--version"], "nth": 3}
  baseTemplate = fetchurl {
    url = "https://raw.githubusercontent.com/lima-vm/lima/v${version}/templates/docker.yaml";
    hash = "sha256-XH+CcaBX+1igLYzgKi69WlM/AokJ5csA8nMXfcCl1JU=";
  };
  patchYaml = ../../config/lima/patch.yaml;
in
runCommand "lima-template"
  {
    nativeBuildInputs = [ yq-go ];
    meta = {
      description = "Generated Lima template with Docker and customized Nix/home-manager provisioning";
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

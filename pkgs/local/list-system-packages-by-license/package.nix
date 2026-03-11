{ writeShellApplication, nix, jq }:

writeShellApplication {
  name = "list-system-packages-by-license";
  runtimeInputs = [
    nix
    jq
  ];
  text = builtins.readFile ./list-system-packages-by-license.bash;
}

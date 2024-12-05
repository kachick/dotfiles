{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "commit-msg";
  text = builtins.readFile ./${name}.bash;
  meta.description = "#325";
  runtimeInputs = with pkgs; [
    typos
    (import ../run_local_hook/package.nix { inherit pkgs; })
  ];
  runtimeEnv = {
    TYPOS_CONFIG_PATH = "${../../typos.toml}";
  };
}

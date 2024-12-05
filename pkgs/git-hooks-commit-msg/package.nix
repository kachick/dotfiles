{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "commit-msg";
  text = builtins.readFile ./${name}.bash;
  meta.description = "#325";
  runtimeInputs = with pkgs; [
    typos
    my.run_local_hook
  ];
  runtimeEnv = {
    TYPOS_CONFIG_PATH = "${../../typos.toml}";
  };
}

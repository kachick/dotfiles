{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "pre-push";
  text = builtins.readFile ./${name}.bash;
  meta.description = "#540";
  runtimeInputs = with pkgs; [
    typos
    coreutils # `basename`
    my.run_local_hook
  ];
  runtimeEnv = {
    TYPOS_CONFIG_PATH = "${../../typos.toml}";
  };
}

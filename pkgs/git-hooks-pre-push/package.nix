{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "pre-push";
  text = builtins.readFile ./${name}.bash;
  meta.description = "GH-540 and GH-699";
  runtimeInputs = with pkgs; [
    typos
    coreutils # `basename`
    unstable.trufflehog
    my.run_local_hook
  ];
  runtimeEnv = {
    TYPOS_CONFIG_PATH = "${../../typos.toml}";
  };
}

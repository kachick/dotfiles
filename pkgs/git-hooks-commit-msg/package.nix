{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "commit-msg";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    typos
    unstable.gitleaks
    my.run_local_hook
  ];
  runtimeEnv = {
    TYPOS_CONFIG_PATH = "${../../typos.toml}";
  };
  meta = {
    description = "GH-325. Typo checker for commit-msg git hook";
  };
}

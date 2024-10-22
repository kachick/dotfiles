{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "envs";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    coreutils # `sort`, `tr`
    fzf
    findutils # `xargs
    ruby_3_3 # pkgs.writers.writeRuby and writeRubyBin does not fit
  ];
  runtimeEnv = {
    RUBY_SCRIPT_PATH = ./${name}.rb;
  };
}

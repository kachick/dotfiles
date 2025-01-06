{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "envs";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fzf
    ruby_3_4 # pkgs.writers.writeRuby and writeRubyBin does not fit
  ];
  runtimeEnv = {
    RUBY_SCRIPT_PATH = "${./${name}.rb}";
  };
  meta = {
    description = "List environment variables";
  };
}

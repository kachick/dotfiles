{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "plamo-trans";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    curl
    jq
    coreutils
  ];
  meta = {
    description = "Translate text using local PLaMo-3-Translate via llama-server";
    mainProgram = name;
  };
}

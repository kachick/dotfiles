{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "git-show-ja";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    gitMinimal
    coreutils
    gawk
    curl
    local.plamo-trans
  ];
  meta = {
    description = "Show git commit with Japanese translation appended to commit message";
    mainProgram = name;
  };
}

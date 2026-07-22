{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "git-log-simple";
  text = builtins.readFile ./git-log-simple.bash;
  runtimeInputs = with pkgs; [ gitMinimal ];
  meta = {
    description = "Beautify git log with keeping the lightweight";
  };
}

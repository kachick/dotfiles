{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "chrome-with-profile-by-name";
  text = builtins.readFile ./chrome-with-profile-by-name.bash;
  runtimeInputs = with pkgs; [
    # Don't add chrome in this dependency. Using with the command name is enough for this purpose
    jq
  ];
  meta = {
    description = "GH-968";
  };
}

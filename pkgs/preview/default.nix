{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "preview";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs =
    (with pkgs; [
      file # Detect file/mime type
      coreutils # For `basename`
      bat # code
      hexyl # binary
      # libsixel
    ])
    ++ [
      (import ../la { inherit pkgs; }) # directory
      (import ../renmark { inherit pkgs; }) # Markdown
    ];
  # Especially provided for fzf: https://github.com/junegunn/fzf/issues/2855#issuecomment-1164015794
  meta.description = "Run preview commands that are suitable for the file type";
}

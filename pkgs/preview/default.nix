{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "preview";
  text = builtins.readFile ./${name}.bash;
  # TODO: Support KDL highlight
  # - bat does not support KDL, however TUI editors with pipe is not to be easy handled
  # - Helix does not have readonly mode and the KDL highlighting is not correct
  #   https://github.com/helix-editor/helix/discussions/9245
  # - micro https://github.com/kachick/micro-kdl
  # - vim https://github.com/imsnif/kdl.vim
  runtimeInputs =
    (with pkgs; [
      file # Detect file/mime type
      coreutils # For `basename`
      bat # code
      hexyl # binary
      # libsixel
      mdcat # markdown - Avoid renmark to keep compatibility in darwin
    ])
    ++ [
      (import ../la { inherit pkgs; }) # directory
    ];
  # Especially provided for fzf: https://github.com/junegunn/fzf/issues/2855#issuecomment-1164015794
  meta.description = "Run preview commands that are suitable for the file type";
}

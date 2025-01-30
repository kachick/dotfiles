{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "ir";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [
    fd

    # Why not other candidates?
    #   - sed: Always forgot how to use. And the regex is much classic
    #   - sd: Inactive
    #   - fastmod: Does not fit for list based preview
    #   - srgn: Much options, but I don't know how to use that
    sad

    unstable.fzf # Require latest to enable new options. e.g `--input-label` # TODO: Prefer stable since nixos-25.05
    riffdiff
  ];
  runtimeEnv = {
    GIT_PAGER = "riff --color=on";
  };
  meta = {
    description = ''
      Inline replacer with a preview UI.
      This is also a note on how to use "sad" with external dependencies.
    '';
  };
}

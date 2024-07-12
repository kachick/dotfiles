{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "check_no_dirty_xz_in_nix_store";
  text = builtins.readFile ./${name}.bash;
  runtimeInputs = with pkgs; [ fd ];
  meta = {
    description = "Prevent #530 (around CVE-2024-3094)";
  };
}

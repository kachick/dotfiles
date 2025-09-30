# Imported from https://github.com/NixOS/nixpkgs/pull/445583/ for testing

{
  pkgs,
}:

pkgs.my.ringboard.override {
  pname = "ringboard-wayland";
  displayServer = "wayland";
}

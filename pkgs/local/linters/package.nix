{ pkgs, ... }:

pkgs.buildEnv {
  name = "linters";
  paths = with pkgs.unstable; [
    # nixfmt # Finally used this package name again. See https://github.com/NixOS/nixpkgs/pull/425068 for detail
    # gitleaks
    typos
    # lychee
    dprint
    # zizmor
    # rumdl # Available since https://github.com/NixOS/nixpkgs/pull/446292
  ];
}

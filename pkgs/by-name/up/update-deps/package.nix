{ pkgs, ... }:
pkgs.writeShellApplication {
  name = "update-deps";

  runtimeInputs = [
    pkgs.pinned.selfup
    pkgs.local.bump_gomod
    pkgs.gitMinimal
    pkgs.findutils
    pkgs.go-task
    pkgs.unstable.dprint
    pkgs.unstable.typos
    pkgs.unstable.betterleaks
  ];

  text = ''
    git ls-files -z .github | xargs --null selfup run "$@" --
    bump_gomod .
  '';

  meta = {
    description = "Update CI dependencies with selfup and related tools";
  };
}

{ pkgs, ... }:

pkgs.buildEnv {
  name = "ci-packages";
  paths =
    (with pkgs; [
      go-task
    ])
    ++ (pkgs.lib.optionals pkgs.stdenv.isLinux (
      (with pkgs; [
        nixf-diagnose

        shellcheck
        shfmt

        # We don't need to consider about treefmt1 https://github.com/NixOS/nixpkgs/pull/387745
        treefmt

        trivy

        desktop-file-utils # `desktop-file-validate` as a linter
        kanata # Enable on devshell for using the --check as a linter
      ])
      ++ (with pkgs.unstable; [
        nixfmt # Finally used this package name again. See https://github.com/NixOS/nixpkgs/pull/425068 for detail
        gitleaks
        typos
        lychee
        dprint
        zizmor
        rumdl # Available since https://github.com/NixOS/nixpkgs/pull/446292
        go_1_26
      ])
      ++ (with pkgs.local; [
        nix-hash-url
      ])
    ));
}

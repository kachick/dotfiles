{ pkgs ? import
    (fetchTarball
      "https://releases.nixos.org/nixpkgs/nixpkgs-23.11pre509044.3acb5c4264c4/nixexprs.tar.xz")
    { }
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.dprint
    pkgs.shellcheck
    pkgs.shfmt
    pkgs.nil
    pkgs.nixpkgs-fmt
    pkgs.gitleaks
    pkgs.cargo-make
    pkgs.typos
    pkgs.go_1_20
  ];
}

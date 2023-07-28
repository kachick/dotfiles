{ pkgs ? import
    (fetchTarball
      "https://github.com/NixOS/nixpkgs/archive/66ce081fafa2dca0038006ec7c6482d7a11d13d8.tar.gz")
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

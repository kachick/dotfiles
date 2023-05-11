{ pkgs ? import
    (fetchTarball
      "https://github.com/NixOS/nixpkgs/archive/25603863bc045c5a6762b4f69acc2cc7312b5d57.tar.gz")
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
    pkgs.coreutils
    pkgs.fd
  ];
}

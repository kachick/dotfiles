{ pkgs ? import
    (fetchTarball
      "https://releases.nixos.org/nixpkgs/nixpkgs-23.11pre509044.3acb5c4264c4/nixexprs.tar.xz")
    { }
}:

pkgs.mkShell {
  buildInputs = with pkgs;
    [
      # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
      bashInteractive

      dprint
      shellcheck
      shfmt
      nil
      nixpkgs-fmt
      gitleaks
      cargo-make
      typos
      go_1_20
    ];
}

{
  inputs = {
    nixpkgs = { url = "https://github.com/NixOS/nixpkgs/archive/8eabb500ebf5dcb9a40024c1150ef348cefa8320.tar.gz"; };
  };


  outputs = { self, nixpkgs }: with nixpkgs.legacyPackages.x86_64-linux; {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;

    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    devShell.x86_64-linux = mkShell {
      buildInputs = [
        dprint
        shellcheck
        shfmt
        nil
        nixpkgs-fmt
        gitleaks
        cargo-make
      ];
    };
  };
}

{
  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # https://github.com/nix-community/home-manager/blob/master/docs/nix-flakes.adoc
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
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

              # To get sha256 around pkgs.fetchFromGitHub in CLI
              nix-prefetch-git
              jq
            ];
          };

        homeConfigurations =
          {
            kachick = home-manager.lib.homeManagerConfiguration {
              # inherit system pkgs;

              pkgs = nixpkgs.legacyPackages.x86_64-linux;

              modules = [
                ./home-manager/home.nix
              ];

              # pkgs = nixpkgs.legacyPackages.${system};
              # pkgs = nixpkgs.legacyPackages.x86_64-linux;
            };
          };
      }
    );
}

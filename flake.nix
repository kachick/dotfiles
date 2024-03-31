{
  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    edge-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    my-nixpkgs.url = "github:kachick/nixpkgs/init-plemoljp-font";
    flake-utils.url = "github:numtide/flake-utils";
    # https://github.com/nix-community/home-manager/blob/master/docs/nix-flakes.adoc
    home-manager = {
      # candidates: "github:nix-community/home-manager/release-23.05";
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, edge-nixpkgs, home-manager, flake-utils, my-nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        edge-pkgs = edge-nixpkgs.legacyPackages.${system};
        my-pkgs = my-nixpkgs.legacyPackages.${system};
      in
      rec {
        # Q. Why nixpkgs-fmt? Not nixfmt? and alejandra?
        # A. nixfmt will be official, but too opinionated and non stable now
        # - https://github.com/NixOS/nixfmt/issues/153
        # - https://github.com/NixOS/nixfmt/issues/129
        # - https://github.com/NixOS/rfcs/pull/166
        # - https://github.com/NixOS/nixfmt/blob/a81f922a2b362f347a6cbecff5fb14f3052bc25d/README.md#L19
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
              bashInteractive
              edge-pkgs.nixpkgs-fmt
              edge-pkgs.nixfmt # Using a sub formatter
              edge-pkgs.nil

              edge-pkgs.dprint
              shellcheck
              shfmt
              gitleaks
              cargo-make
              edge-pkgs.typos
              edge-pkgs.go_1_22
              goreleaser
              trivy

              # To get sha256 around pkgs.fetchFromGitHub in CLI
              nix-prefetch-git
              jq
            ];
          };

        packages.homeConfigurations = {
          kachick = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [ ./home-manager/kachick.nix ];
            extraSpecialArgs = {
              inherit edge-pkgs;
              inherit my-pkgs;
            };
          };

          github-actions = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              # Prefer "kachick" over "common" only here.
              # Using values as much as possible as actual values to create a robust CI
              ./home-manager/kachick.nix
              { home.username = "runner"; }
            ];
            extraSpecialArgs = {
              inherit edge-pkgs;
              inherit my-pkgs;
            };
          };

          user = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./home-manager/common.nix
              {
                # "user" is default in podman-machine-default
                home.username = "user";
              }
            ];
            extraSpecialArgs = {
              inherit edge-pkgs;
              inherit my-pkgs;
            };
          };
        };

        packages.bump_completions =
          pkgs.writeShellScriptBin "bump_completions" ''
            set -euo pipefail

            ${edge-pkgs.podman}/bin/podman completion bash > ./dependencies/podman/completions.bash
            ${edge-pkgs.podman}/bin/podman completion zsh > ./dependencies/podman/completions.zsh
            ${edge-pkgs.podman}/bin/podman completion fish > ./dependencies/podman/completions.fish

            ${edge-pkgs.dprint}/bin/dprint completions bash > ./dependencies/dprint/completions.bash
            ${edge-pkgs.dprint}/bin/dprint completions zsh > ./dependencies/dprint/completions.zsh
            ${edge-pkgs.dprint}/bin/dprint completions fish > ./dependencies/dprint/completions.fish
          '';

        apps = {
          # example: `nix run .#home-manager -- switch -n -b backup --flake .#kachick`
          # https://github.com/NixOS/nix/issues/6448#issuecomment-1132855605
          home-manager = flake-utils.lib.mkApp {
            drv = home-manager.defaultPackage.${system};
          };

          bump_completions = {
            type = "app";
            program = "${packages.bump_completions}/bin/bump_completions";
          };
        };
      });
}


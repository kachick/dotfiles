{
  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    edge-nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # https://github.com/nix-community/home-manager/blob/master/docs/nix-flakes.adoc
    home-manager = {
      # candidates: "github:nix-community/home-manager/release-23.05";
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, edge-nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        edge-pkgs = edge-nixpkgs.legacyPackages.${system};
      in
      rec {
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
              go_1_22
              goreleaser
              trivy

              # To get sha256 around pkgs.fetchFromGitHub in CLI
              nix-prefetch-git
              jq
            ];
          };

        packages.homeConfigurations =
          {
            kachick = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                ./home-manager/kachick.nix
              ];
              extraSpecialArgs = {
                inherit edge-pkgs;
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
              };
            };
          };

        packages.bump_completions = pkgs.writeShellScriptBin "bump_completions" ''
          set -euo pipefail

          ${pkgs.podman}/bin/podman completion bash > ./dependencies/podman/completions.bash
          ${pkgs.podman}/bin/podman completion zsh > ./dependencies/podman/completions.zsh
          ${pkgs.podman}/bin/podman completion fish > ./dependencies/podman/completions.fish

          ${pkgs.dprint}/bin/dprint completions bash > ./dependencies/dprint/completions.bash
          ${pkgs.dprint}/bin/dprint completions zsh > ./dependencies/dprint/completions.zsh
          ${pkgs.dprint}/bin/dprint completions fish > ./dependencies/dprint/completions.fish
        '';

        # https://gist.github.com/Scoder12/0538252ed4b82d65e59115075369d34d?permalink_comment_id=4650816#gistcomment-4650816
        packages.json2nix = pkgs.writeScriptBin "json2nix" ''
          ${pkgs.python3}/bin/python ${pkgs.fetchurl {
            url = "https://gist.githubusercontent.com/Scoder12/0538252ed4b82d65e59115075369d34d/raw/e86d1d64d1373a497118beb1259dab149cea951d/json2nix.py";
            hash = "sha256-ROUIrOrY9Mp1F3m+bVaT+m8ASh2Bgz8VrPyyrQf9UNQ=";
          }} $@
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

          # example: `nix run .#json2nix gitconfig.json`
          json2nix = {
            type = "app";
            program = "${packages.json2nix}/bin/json2nix";
          };
        };
      }
    );
}


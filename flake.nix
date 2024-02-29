{
  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # https://github.com/nix-community/home-manager/blob/master/docs/nix-flakes.adoc
    home-manager = {
      # candidates: "github:nix-community/home-manager/release-23.05";
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
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
            };

            github-actions = home-manager.lib.homeManagerConfiguration {
              inherit pkgs;
              modules = [
                # Prefer "kachick" over "common" only here.
                # Using values as much as possible as actual values to create a robust CI
                ./home-manager/kachick.nix
                { home.username = "runner"; }
              ];
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
            };
          };

        packages.enable_nix_login_shells = pkgs.stdenv.mkDerivation
          {
            name = "enable_nix_login_shells";
            src = self;
            buildInputs = with pkgs; [
              go_1_22
            ];
            buildPhase = ''
              # https://github.com/NixOS/nix/issues/670#issuecomment-1211700127
              export HOME=$(pwd)
              go build -o dist/enable_nix_login_shells ./cmd/enable_nix_login_shells
            '';
            installPhase = ''
              mkdir -p $out/bin
              install -t $out/bin dist/enable_nix_login_shells
            '';
          };

        packages.sudo_enable_nix_login_shells = pkgs.writeShellScriptBin "sudo_enable_nix_login_shells" ''
          set -euo pipefail

          # Don't use nixpkgs provided sudo here to avoid "sudo must be owned by uid 0 and have the setuid bit set"
          sudo -E ${packages.enable_nix_login_shells}/bin/enable_nix_login_shells "$@"
        '';

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

          sudo_enable_nix_login_shells = {
            type = "app";
            program = "${packages.sudo_enable_nix_login_shells}/bin/sudo_enable_nix_login_shells";
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


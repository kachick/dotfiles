{
  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    edge-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # https://github.com/nix-community/home-manager/blob/release-23.11/docs/manual/nix-flakes.md
    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, edge-nixpkgs, home-manager, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        edge-pkgs = edge-nixpkgs.legacyPackages.${system};
      in
      rec {
        # Q. Why nixpkgs-fmt? Not nixfmt? and alejandra?
        # A. nixfmt will be official, but too opinionated and non stable now
        # - https://github.com/NixOS/nixfmt/issues/153
        # - https://github.com/NixOS/nixfmt/issues/129
        # - https://github.com/NixOS/rfcs/pull/166
        # - https://github.com/NixOS/nixfmt/blob/a81f922a2b362f347a6cbecff5fb14f3052bc25d/README.md#L19
        formatter = edge-pkgs.nixpkgs-fmt;
        devShells.default = with pkgs;
          mkShell {
            buildInputs = [
              # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
              bashInteractive
              edge-pkgs.nixpkgs-fmt
              edge-pkgs.nixfmt-rfc-style # Using as a sub formatter for now, the command is still `nixfmt`
              edge-pkgs.nil
              # To get sha256 around pkgs.fetchFromGitHub in CLI
              nix-prefetch-git
              jq

              shellcheck
              shfmt
              gitleaks
              cargo-make

              edge-pkgs.dprint
              edge-pkgs.typos
              edge-pkgs.go_1_22
              edge-pkgs.goreleaser
              edge-pkgs.trivy
            ];
          };

        packages.homeConfigurations = {
          kachick = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [ ./home-manager/kachick.nix ];
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

        packages.check_no_dirty_xz_in_nix_store =
          pkgs.writeShellApplication {
            name = "check_no_dirty_xz_in_nix_store";
            runtimeInputs = with pkgs; [ fd ];
            text = ''
              # nix store should have xz: https://github.com/NixOS/nixpkgs/blob/b96bc828b81140dd3fb096b4e66a6446d6d5c9dc/doc/stdenv/stdenv.chapter.md?plain=1#L177
              # You can't use --max-results instead of --has-results even if you want the log, it always returns true
              fd '^\w+-xz-[0-9\.]+\.drv' --search-path /nix/store --has-results

              # Why toggling errexit and return code here: https://github.com/kachick/times_kachick/issues/278
              set +o errexit
              fd '^\w+-xz-5\.6\.[01]\.drv' --search-path /nix/store --has-results
              fd_return_code="$?" # Do not directly use the $? to prevent feature broken if inserting another command before check
              set -o errexit
              [[ "$fd_return_code" -eq 1 ]]
            '';
            meta = {
              description = "Prevent #530 (around CVE-2024-3094)";
            };
          };

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

          check_no_dirty_xz_in_nix_store = {
            type = "app";
            program = "${packages.check_no_dirty_xz_in_nix_store}/bin/check_no_dirty_xz_in_nix_store";
          };
        };
      });
}


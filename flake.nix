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

  outputs =
    {
      self,
      nixpkgs,
      edge-nixpkgs,
      home-manager,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        edge-pkgs = edge-nixpkgs.legacyPackages.${system};
      in
      rec {
        # nixfmt will be official
        # - https://github.com/NixOS/nixfmt/issues/153
        # - https://github.com/NixOS/nixfmt/issues/129
        # - https://github.com/NixOS/rfcs/pull/166
        # - https://github.com/NixOS/nixfmt/blob/a81f922a2b362f347a6cbecff5fb14f3052bc25d/README.md#L19
        formatter = edge-pkgs.nixfmt-rfc-style;
        devShells.default =
          with pkgs;
          mkShell {
            buildInputs = [
              # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
              bashInteractive
              edge-pkgs.nixfmt-rfc-style
              edge-pkgs.nil
              # To get sha256 around pkgs.fetchFromGitHub in CLI
              nix-prefetch-git
              jq

              shellcheck
              shfmt
              gitleaks
              cargo-make

              edge-pkgs.dprint
              edge-pkgs.yamlfmt
              edge-pkgs.typos
              edge-pkgs.typos-lsp
              edge-pkgs.go_1_22
              edge-pkgs.goreleaser
              edge-pkgs.trivy
            ];

            # Needed for some dprint plugins, prettier and exec
            NIX_LD = lib.fileContents "${stdenv.cc}/nix-support/dynamic-linker";
          };

        packages.homeConfigurations = {
          kachick = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [ ./home-manager/kachick.nix ];
            extraSpecialArgs = {
              inherit edge-pkgs;
            };
          };

          wsl = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ./home-manager/kachick.nix
              ./home-manager/wsl.nix
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
              { home.username = "user"; }
            ];
            extraSpecialArgs = {
              inherit edge-pkgs;
            };
          };
        };

        apps = {
          # example: `nix run .#home-manager -- switch -n -b backup --flake .#kachick`
          # https://github.com/NixOS/nix/issues/6448#issuecomment-1132855605
          home-manager = flake-utils.lib.mkApp { drv = home-manager.defaultPackage.${system}; };

          bump_completions = {
            type = "app";
            program =
              with pkgs;
              lib.getExe (writeShellApplication {
                name = "bump_completions";
                runtimeInputs = with pkgs; [
                  git
                  edge-pkgs.podman
                  edge-pkgs.dprint
                ];
                text = ''
                  podman completion bash > ./dependencies/podman/completions.bash
                  podman completion zsh > ./dependencies/podman/completions.zsh
                  podman completion fish > ./dependencies/podman/completions.fish

                  git add ./dependencies/podman
                  # https://stackoverflow.com/q/34807971
                  git update-index -q --really-refresh
                  git diff-index --quiet HEAD || git commit -m 'Update podman completions' ./dependencies/podman

                  dprint completions bash > ./dependencies/dprint/completions.bash
                  dprint completions zsh > ./dependencies/dprint/completions.zsh
                  dprint completions fish > ./dependencies/dprint/completions.fish

                  git add ./dependencies/dprint
                  git update-index -q --really-refresh
                  git diff-index --quiet HEAD || git commit -m 'Update dprint completions' ./dependencies/dprint
                '';
                meta = {
                  description = "Bump shell completions with cached files to make faster";
                };
              });
          };

          bump_lsp = {
            type = "app";
            program =
              with pkgs;
              lib.getExe (writeShellApplication {
                name = "bump_lsp";
                runtimeInputs = with pkgs; [
                  git
                  nix
                  edge-pkgs.typos-lsp
                ];
                text = ''
                  git ls-files .vscode | xargs nix run github:kachick/selfup/v1.1.2 -- run
                  git diff-index --quiet HEAD || git commit -m 'Sync LSP path with nixpkgs' .vscode
                '';
                meta = {
                  description = "Bump typos-lsp";
                };
              });
          };

          check_no_dirty_xz_in_nix_store = {
            type = "app";
            program =
              with pkgs;
              lib.getExe (writeShellApplication {
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
              });
          };
        };
      }
    );
}

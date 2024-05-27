{
  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    edge-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # https://github.com/nix-community/home-manager/blob/release-24.05/docs/manual/nix-flakes.md
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      edge-nixpkgs,
      home-manager,
    }:
    let
      # Candidates: https://github.com/NixOS/nixpkgs/blob/release-24.05/lib/systems/flake-systems.nix
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "x86_64-darwin"
        # I don't have M1+ mac, providing this for macos-14 free runner https://github.com/actions/runner-images/issues/9741
        "aarch64-darwin"
      ];
    in
    rec {
      # nixfmt will be official
      # - https://github.com/NixOS/nixfmt/issues/153
      # - https://github.com/NixOS/nixfmt/issues/129
      # - https://github.com/NixOS/rfcs/pull/166
      # - https://github.com/NixOS/nixfmt/blob/a81f922a2b362f347a6cbecff5fb14f3052bc25d/README.md#L19
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          edge-pkgs = edge-nixpkgs.legacyPackages.${system};
        in
        {
          default =
            with pkgs;
            mkShell {
              buildInputs = [
                # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
                bashInteractive
                nixfmt-rfc-style
                nil
                # To get sha256 around pkgs.fetchFromGitHub in CLI
                nix-prefetch-git
                jq

                shellcheck
                shfmt
                gitleaks
                cargo-make

                dprint
                # TODO: Use stable if https://github.com/google/yamlfmt/pull/179 is released
                edge-pkgs.yamlfmt
                typos
                go_1_22
                goreleaser
                trivy
              ];
            };
        }
      );

      packages = forAllSystems (
        system:
        (import ./pkgs {
          pkgs = nixpkgs.legacyPackages.${system};
          edge-pkgs = edge-nixpkgs.legacyPackages.${system};
        })
      );

      apps = forAllSystems (system: {
        # example: `nix run .#home-manager -- switch -n -b backup --flake .#user@linux`
        # https://github.com/NixOS/nix/issues/6448#issuecomment-1132855605
        home-manager = {
          type = "app";
          program = "${home-manager.defaultPackage.${system}}/bin/home-manager";
        };

        bump_completions = {
          type = "app";
          program = "${packages.${system}.bump_completions}/bin/bump_completions";
        };

        check_no_dirty_xz_in_nix_store = {
          type = "app";
          program = "${packages.${system}.check_no_dirty_xz_in_nix_store}/bin/check_no_dirty_xz_in_nix_store";
        };

        bench_shells = {
          type = "app";
          program = "${packages.${system}.bench_shells}/bin/bench_shells";
        };

        walk = {
          type = "app";
          program = "${packages.${system}.walk}/bin/walk";
        };

        todo = {
          type = "app";
          program = "${packages.${system}.todo}/bin/todo";
        };

        la = {
          type = "app";
          program = "${packages.${system}.la}/bin/la";
        };

        lat = {
          type = "app";
          program = "${packages.${system}.lat}/bin/lat";
        };

        ghqf = {
          type = "app";
          program = "${packages.${system}.ghqf}/bin/ghqf";
        };

        git-delete-merged-branches = {
          type = "app";
          program = "${packages.${system}.git-delete-merged-branches}/bin/git-delete-merged-branches";
        };

        git-log-fzf = {
          type = "app";
          program = "${packages.${system}.git-log-fzf}/bin/git-log-fzf";
        };
      });

      homeConfigurations = {
        "kachick@linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./home-manager/kachick.nix ];
          extraSpecialArgs = {
            homemade-pkgs = packages.x86_64-linux;
            edge-pkgs = edge-nixpkgs.legacyPackages.x86_64-linux;
          };
        };

        "kachick@wsl" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home-manager/kachick.nix
            ./home-manager/wsl.nix
          ];
          extraSpecialArgs = {
            homemade-pkgs = packages.x86_64-linux;
            edge-pkgs = edge-nixpkgs.legacyPackages.x86_64-linux;
          };
        };

        "kachick@macbook" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-darwin;
          modules = [ ./home-manager/kachick.nix ];
          extraSpecialArgs = {
            homemade-pkgs = packages.x86_64-darwin;
            edge-pkgs = edge-nixpkgs.legacyPackages.x86_64-darwin;
          };
        };

        "github-actions@ubuntu-24.04" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            # Prefer "kachick" over "common" only here.
            # Using values as much as possible as actual values to create a robust CI
            ./home-manager/kachick.nix
            { home.username = "runner"; }
          ];
          extraSpecialArgs = {
            homemade-pkgs = packages.x86_64-linux;
            edge-pkgs = edge-nixpkgs.legacyPackages.x86_64-linux;
          };
        };

        "github-actions@macos-14" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          modules = [
            # Prefer "kachick" over "common" only here.
            # Using values as much as possible as actual values to create a robust CI
            ./home-manager/kachick.nix
            { home.username = "runner"; }
          ];
          extraSpecialArgs = {
            homemade-pkgs = packages.aarch64-darwin;
            edge-pkgs = edge-nixpkgs.legacyPackages.aarch64-darwin;
          };
        };

        "user@linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home-manager/common.nix
            { home.username = "user"; }
          ];
          extraSpecialArgs = {
            homemade-pkgs = packages.x86_64-linux;
            edge-pkgs = edge-nixpkgs.legacyPackages.x86_64-linux;
          };
        };
      };
    };
}

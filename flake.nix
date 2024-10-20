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
    nixos-wsl.url = "github:nix-community/NixOS-WSL/2405.5.4";
    # https://github.com/xremap/nix-flake/blob/master/docs/HOWTO.md
    xremap-flake.url = "github:xremap/nix-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      edge-nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      # Candidates: https://github.com/NixOS/nixpkgs/blob/release-24.05/lib/systems/flake-systems.nix
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;

      mkApp = pkg: {
        type = "app";
        program = nixpkgs.lib.getExe pkg;
      };

      homemade-packages = forAllSystems (
        system:
        (nixpkgs.legacyPackages.${system}.callPackage ./pkgs {
          edge-pkgs = edge-nixpkgs.legacyPackages.${system};
        })
      );
    in
    {
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
          homemade-pkgs = homemade-packages.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            # Realize nixd pkgs version inlay hints for stable channel instead of latest
            NIX_PATH = "nixpkgs=${pkgs.path}";

            TYPOS_LSP_PATH = pkgs.lib.getExe pkgs.typos-lsp; # For vscode typos extension

            buildInputs =
              (with pkgs; [
                # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
                bashInteractive
                nixfmt-rfc-style
                nixpkgs-lint-community
                nix-init
                nurl

                shellcheck
                shfmt
                gitleaks
                cargo-make

                dprint
                stylua
                typos
                typos-lsp # For zed-editor typos extension
                go_1_23
                goreleaser
                trivy
              ])
              ++ (with edge-pkgs; [
                nixd
                # Don't use treefmt(treefmt1) that does not have crucial feature to cover hidden files
                # https://github.com/numtide/treefmt/pull/250
                treefmt2
                markdownlint-cli2
              ])
              ++ (with homemade-pkgs; [ nix-hash-url ]);
          };
        }
      );

      packages = forAllSystems (system: {
        cozette = homemade-packages.${system}.cozette;
        micro-kdl = homemade-packages.${system}.micro-kdl;
      });

      apps = forAllSystems (
        system:
        builtins.listToAttrs (
          (map
            (name: {
              inherit name;
              value = mkApp homemade-packages.${system}.${name};
            })
            [
              "bump_completions"
              "bump_gomod"
              "check_no_dirty_xz_in_nix_store"
              "check_nixf"
              "bench_shells"
              "walk"
              "ir"
              "todo"
              "la"
              "lat"
              "zed"
              "ghqf"
              "git-delete-merged-branches"
              "git-log-fzf"
              "git-log-simple"
              "git-resolve-conflict"
              "gh-prs"
              "nix-hash-url"
              "reponame"
              "gredit"
              "renmark"
              "preview"
              "p"
            ]
          )
          ++ [
            # example: `nix run .#home-manager -- switch -n -b backup --flake .#user@linux-cli`
            # https://github.com/NixOS/nix/issues/6448#issuecomment-1132855605
            {
              name = "home-manager";
              value = mkApp home-manager.defaultPackage.${system};
            }
          ]
        )
      );

      nixosConfigurations =
        let
          system = "x86_64-linux";
          edge-pkgs = import edge-nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
          homemade-pkgs = homemade-packages.${system};
          shared = {
            inherit system;
            specialArgs = {
              inherit
                inputs
                outputs
                homemade-pkgs
                edge-pkgs
                ;
            };
          };
        in
        {
          "moss" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./nixos/hosts/moss ]; });
          "algae" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./nixos/hosts/algae ]; });
          "wsl" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./nixos/hosts/wsl ]; });
        };

      homeConfigurations =
        let
          x86-Linux = {
            pkgs = nixpkgs.legacyPackages.x86_64-linux;
            extraSpecialArgs = {
              homemade-pkgs = homemade-packages.x86_64-linux;
              edge-pkgs = edge-nixpkgs.legacyPackages.x86_64-linux;
            };
          };

          x86-macOS =
            let
              system = "x86_64-darwin";
            in
            {
              pkgs = nixpkgs.legacyPackages.${system};
              extraSpecialArgs = {
                homemade-pkgs = homemade-packages.${system};
                edge-pkgs = import edge-nixpkgs {
                  inherit system;
                  config = {
                    # Atleast required for following
                    # signal-desktop: https://github.com/NixOS/nixpkgs/pull/348165/files#diff-05921dc46b537c59c8a76dfc3c3e9a3a1fd93345ee5bff8573aae36dedf719bcR49
                    # android-studio: https://github.com/NixOS/nixpkgs/blob/3490095db7c455272ee96c1d99d424d029bdf576/pkgs/applications/editors/android-studio/common.nix#L281
                    allowUnfree = true;
                  };
                };
              };
            };

          aarch64-macOS =
            let
              system = "aarch64-darwin";
            in
            {
              pkgs = nixpkgs.legacyPackages.${system};
              extraSpecialArgs = {
                homemade-pkgs = homemade-packages.${system};
                edge-pkgs = import edge-nixpkgs {
                  inherit system;
                  config = {
                    allowUnfree = true;
                  };
                };
              };
            };
        in
        {
          "kachick@desktop" = home-manager.lib.homeManagerConfiguration (
            x86-Linux
            // {
              modules = [
                ./home-manager/kachick.nix
                ./home-manager/systemd.nix
                ./home-manager/gnome.nix
              ];
            }
          );

          "kachick@wsl" = home-manager.lib.homeManagerConfiguration (
            x86-Linux
            // {
              modules = [
                ./home-manager/kachick.nix
                ./home-manager/wsl.nix
              ];
            }
          );

          "kachick@macbook" = home-manager.lib.homeManagerConfiguration (
            x86-macOS // { modules = [ ./home-manager/kachick.nix ]; }
          );

          "github-actions@ubuntu-24.04" = home-manager.lib.homeManagerConfiguration (
            x86-Linux
            // {
              # Prefer "kachick" over "common" only here.
              # Using values as much as possible as actual values to create a robust CI
              modules = [
                ./home-manager/kachick.nix
                { home.username = "runner"; }
                ./home-manager/systemd.nix
              ];
            }
          );

          "github-actions@macos-13" = home-manager.lib.homeManagerConfiguration (
            x86-macOS
            // {
              # Prefer "kachick" over "common" only here.
              # Using values as much as possible as actual values to create a robust CI
              modules = [
                ./home-manager/kachick.nix
                { home.username = "runner"; }
              ];
            }
          );

          "github-actions@macos-15" = home-manager.lib.homeManagerConfiguration (
            aarch64-macOS
            // {
              # Prefer "kachick" over "common" only here.
              # Using values as much as possible as actual values to create a robust CI
              modules = [
                ./home-manager/kachick.nix
                { home.username = "runner"; }
              ];
            }
          );

          "user@linux-cli" = home-manager.lib.homeManagerConfiguration (
            x86-Linux
            // {
              modules = [
                ./home-manager/common.nix
                { home.username = "user"; }
                ./home-manager/systemd.nix
              ];
            }
          );
        };
    };
}

{
  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    # TODO: Use nixpkgs-24.05-darwin only in macOS. See GH-910
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    edge-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # https://github.com/nix-community/home-manager/blob/release-24.05/docs/manual/nix-flakes.md
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/2405.5.4";
      # https://github.com/nix-community/NixOS-WSL/blob/5a965cb108fb1f30b29a26dbc29b473f49e80b41/flake.nix#L5
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # https://github.com/xremap/nix-flake/blob/master/docs/HOWTO.md
    xremap-flake = {
      url = "github:xremap/nix-flake";
      # https://github.com/xremap/nix-flake/blob/2c55335d6509702b0d337b8da697d7048e36123d/flake.nix#L6
      inputs.nixpkgs.follows = "edge-nixpkgs";
    };
    selfup = {
      url = "github:kachick/selfup/v1.1.6";
      # https://github.com/kachick/selfup/blob/991afc21e437a449c9bd4237b4253f8da407f569/flake.nix#L8
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
                hydra-check # Background and how to use: https://github.com/kachick/dotfiles/pull/909#issuecomment-2453389909

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

                (ruby_3_3.withPackages (ps: with ps; [ rubocop ]))
              ])
              ++ (with edge-pkgs; [
                nixd
                # Don't use treefmt(treefmt1) that does not have crucial feature to cover hidden files
                # https://github.com/numtide/treefmt/pull/250
                treefmt2
                markdownlint-cli2
              ])
              ++ (with homemade-pkgs; [ nix-hash-url ])
              ++ [ inputs.selfup.packages.${system}.default ];
          };
        }
      );

      packages = forAllSystems (system: {
        cozette = homemade-packages.${system}.cozette;
        micro-kdl = homemade-packages.${system}.micro-kdl;
        micro-nordcolors = homemade-packages.${system}.micro-nordcolors;
        micro-everforest = homemade-packages.${system}.micro-everforest;
        micro-catppuccin = homemade-packages.${system}.micro-catppuccin;
        envs = homemade-packages.${system}.envs;
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
              "ghqf"
              "git-delete-merged-branches"
              "git-log-fzf"
              "git-log-simple"
              "git-resolve-conflict"
              "gh-prs"
              "envs"
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

          x86-macOS = {
            pkgs = nixpkgs.legacyPackages.x86_64-darwin;
            extraSpecialArgs = {
              homemade-pkgs = homemade-packages.x86_64-darwin;
              edge-pkgs = edge-nixpkgs.legacyPackages.x86_64-darwin;
            };
          };

          aarch64-macOS = {
            pkgs = nixpkgs.legacyPackages.aarch64-darwin;
            extraSpecialArgs = {
              homemade-pkgs = homemade-packages.aarch64-darwin;
              edge-pkgs = edge-nixpkgs.legacyPackages.aarch64-darwin;
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

          "kachick@wsl-ubuntu" = home-manager.lib.homeManagerConfiguration (
            x86-Linux
            // {
              modules = [
                ./home-manager/kachick.nix
                ./home-manager/wsl.nix
              ];
            }
          );

          "nixos@wsl-nixos" = home-manager.lib.homeManagerConfiguration (
            x86-Linux
            // {
              modules = [
                ./home-manager/kachick.nix
                { home.username = "nixos"; }
                ./home-manager/wsl.nix
              ];
            }
          );

          "kachick@macbook" = home-manager.lib.homeManagerConfiguration (
            x86-macOS // { modules = [ ./home-manager/kachick.nix ]; }
          );

          "kachick@lima" = home-manager.lib.homeManagerConfiguration (
            x86-Linux
            // {
              modules = [
                ./home-manager/kachick.nix
                ./home-manager/lima.nix
              ];
            }
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

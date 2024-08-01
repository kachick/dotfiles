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
    nixos-wsl.url = "github:nix-community/NixOS-WSL/main";
    # https://github.com/xremap/nix-flake/blob/master/docs/HOWTO.md
    xremap-flake.url = "github:xremap/nix-flake";
    # Don't use wezterm-flake for now. The IME on wayland does not work than old stable.
    # wezterm-flake = {
    #   url = "github:wez/wezterm?dir=nix";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs =
    {
      self,
      nixpkgs,
      edge-nixpkgs,
      home-manager,
      nixos-wsl,
      xremap-flake,
    # wezterm-flake,
    }@inputs:
    let
      inherit (self) outputs;
      # Candidates: https://github.com/NixOS/nixpkgs/blob/release-24.05/lib/systems/flake-systems.nix
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "x86_64-darwin"
        # I don't have M1+ mac, providing this for macos-14 free runner https://github.com/actions/runner-images/issues/9741
        "aarch64-darwin"
      ];

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
        in
        {
          default =
            with pkgs;
            mkShellNoCC {
              buildInputs = [
                # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
                bashInteractive
                nixfmt-rfc-style
                # TODO: Consider to replace nil with nixd: https://github.com/oxalica/nil/issues/111
                nil # Used in vscode Nix extension
                nixd # Used in zed Nix extension
                nixpkgs-lint-community
                # To get sha256 around pkgs.fetchFromGitHub in CLI
                nix-prefetch-git
                jq

                shellcheck
                shfmt
                gitleaks
                cargo-make

                # Don't use treefmt(treefmt1) that does not have crucial feature to cover hidden files
                # https://github.com/numtide/treefmt/pull/250
                treefmt2
                dprint
                stylua
                typos
                typos-lsp
                go_1_22
                goreleaser
                trivy
                edge-pkgs.markdownlint-cli2
              ];
            };
        }
      );

      apps = forAllSystems (system: {
        # example: `nix run .#home-manager -- switch -n -b backup --flake .#user@linux-cui`
        # https://github.com/NixOS/nix/issues/6448#issuecomment-1132855605
        home-manager = mkApp home-manager.defaultPackage.${system};
        bump_completions = mkApp homemade-packages.${system}.bump_completions;
        bump_gomod = mkApp homemade-packages.${system}.bump_gomod;
        check_no_dirty_xz_in_nix_store = mkApp homemade-packages.${system}.check_no_dirty_xz_in_nix_store;
        bench_shells = mkApp homemade-packages.${system}.bench_shells;
        walk = mkApp homemade-packages.${system}.walk;
        todo = mkApp homemade-packages.${system}.todo;
        la = mkApp homemade-packages.${system}.la;
        lat = mkApp homemade-packages.${system}.lat;
        ghqf = mkApp homemade-packages.${system}.ghqf;
        git-delete-merged-branches = mkApp homemade-packages.${system}.git-delete-merged-branches;
        git-log-fzf = mkApp homemade-packages.${system}.git-log-fzf;
        git-log-simple = mkApp homemade-packages.${system}.git-log-simple;
        prs = mkApp homemade-packages.${system}.prs;
        trim-github-user-prefix-for-reponame =
          mkApp
            homemade-packages.${system}.trim-github-user-prefix-for-reponame;
      });

      nixosConfigurations =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs { inherit system; };
          edge-pkgs = import edge-nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
          homemade-pkgs = homemade-packages.${system};
          shared = {
            inherit system;
            modules = [
              ./nixos/configuration.nix
              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "backup";
                  # FIXME: Apply gnome.nix in #680
                  users.kachick = import ./home-manager/kachick.nix;
                  extraSpecialArgs = {
                    inherit homemade-pkgs edge-pkgs;
                  };
                };
              }
              xremap-flake.nixosModules.default
              ./nixos/xremap.nix
            ];
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
          "moss" = nixpkgs.lib.nixosSystem (
            shared // { modules = shared.modules ++ [ ./nixos/hosts/moss ]; }
          );
          # "algae" = nixpkgs.lib.nixosSystem (
          #   shared // { modules = shared.modules ++ [ ./nixos/hosts/algae.nix ]; }
          # );

          "nixos-wsl" = nixpkgs.lib.nixosSystem (
            shared
            // {
              modules = shared.modules ++ [
                nixos-wsl.nixosModules.default
                { wsl.enable = true; }
              ];
            }
          );
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
          "kachick@linux-gui" = home-manager.lib.homeManagerConfiguration (
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

          "github-actions@macos-14" = home-manager.lib.homeManagerConfiguration (
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

          "user@linux-cui" = home-manager.lib.homeManagerConfiguration (
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

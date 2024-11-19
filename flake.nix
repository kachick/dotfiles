{
  description = "kachick's dotfiles that can be placed in the public repository";

  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    edge-nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # Better than nixos-unstable until using darwin, however still not enough and might be broken. See https://github.com/NixOS/nixpkgs/issues/107466
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    # https://github.com/nix-community/home-manager/blob/release-24.11/docs/manual/nix-flakes.md
    home-manager-linux = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main"; # TODO: Pin to 2411.?.? if 24.11 conpat channel will be introduced
      # https://github.com/nix-community/NixOS-WSL/blob/5a965cb108fb1f30b29a26dbc29b473f49e80b41/flake.nix#L5
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # https://github.com/xremap/nix-flake/blob/master/docs/HOWTO.md
    # TODO: Prefer nixpkgs version after https://github.com/NixOS/nixpkgs/pull/283278 merged
    xremap-flake = {
      url = "github:xremap/nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
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
      nixpkgs-darwin,
      home-manager-linux,
      home-manager-darwin,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      # Candidates: https://github.com/NixOS/nixpkgs/blob/release-24.11/lib/systems/flake-systems.nix
      forAllSystems = nixpkgs.lib.genAttrs (
        nixpkgs.lib.intersectLists [
          "x86_64-linux"
          "x86_64-darwin"
        ] nixpkgs.lib.systems.flakeExposed
      );

      mkNixpkgs =
        system: if (nixpkgs.lib.strings.hasSuffix "-darwin" system) then nixpkgs-darwin else nixpkgs;

      overlays = import ./overlays { inherit edge-nixpkgs; };

      mkPkgs =
        system:
        import (mkNixpkgs system) {
          inherit system overlays;
        };

      mkHomeManager =
        system:
        if (nixpkgs.lib.strings.hasSuffix "-darwin" system) then
          home-manager-darwin
        else
          home-manager-linux;

      mkApp =
        { system, pkg }:
        {
          type = "app";
          program = (mkNixpkgs system).lib.getExe pkg;
        };
    in
    {
      # nixfmt will be official
      # - https://github.com/NixOS/nixfmt/issues/153
      # - https://github.com/NixOS/nixfmt/issues/129
      # - https://github.com/NixOS/rfcs/pull/166
      # - https://github.com/NixOS/nixfmt/blob/a81f922a2b362f347a6cbecff5fb14f3052bc25d/README.md#L19
      formatter = forAllSystems (system: (mkPkgs system).nixfmt-rfc-style);

      devShells = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
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
                gitleaks
                cargo-make
              ])
              ++ (pkgs.lib.optionals pkgs.stdenv.isLinux (
                (with pkgs; [
                  nixfmt-rfc-style
                  nixd
                  nixf # `nixf-tidy`
                  nixpkgs-lint-community
                  nix-init
                  nurl
                  hydra-check # Background and how to use: https://github.com/kachick/dotfiles/pull/909#issuecomment-2453389909

                  shellcheck
                  shfmt

                  # Don't use treefmt(treefmt1) that does not have crucial feature to cover hidden files
                  # https://github.com/numtide/treefmt/pull/250
                  treefmt2
                  dprint
                  stylua
                  typos
                  typos-lsp # For zed-editor typos extension
                  go_1_23
                  goreleaser
                  trivy
                  markdownlint-cli2

                  (ruby_3_3.withPackages (ps: with ps; [ rubocop ]))
                ])
                ++ (with pkgs.my; [ nix-hash-url ])
                ++ [ inputs.selfup.packages.${system}.default ]
              ));
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          cozette = pkgs.my.cozette;
          micro-kdl = pkgs.my.micro-kdl;
          micro-nordcolors = pkgs.my.micro-nordcolors;
          micro-everforest = pkgs.my.micro-everforest;
          micro-catppuccin = pkgs.my.micro-catppuccin;
          envs = pkgs.my.envs;
        }
      );

      apps = forAllSystems (
        system:
        builtins.listToAttrs (
          (map
            (name: {
              inherit name;
              value = mkApp {
                system = system;
                pkg = (mkPkgs system).my.${name};
              };
            })
            [
              "bump_completions"
              "bump_gomod"
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
              value = mkApp {
                system = system;
                pkg = (mkHomeManager system).defaultPackage.${system};
              };
            }
          ]
        )
      );

      nixosConfigurations =
        let
          system = "x86_64-linux";
          shared = {
            inherit system;
            specialArgs = {
              inherit
                inputs
                outputs
                overlays
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
          x86-Linux-pkgs = mkPkgs "x86_64-linux";
          x86-macOS-pkgs = mkPkgs "x86_64-darwin";
        in
        {
          "kachick@nixos-desktop" = home-manager-linux.lib.homeManagerConfiguration {
            pkgs = x86-Linux-pkgs;
            modules = [
              ./home-manager/kachick.nix
              ./home-manager/linux.nix
              { targets.genericLinux.enable = false; }
              ./home-manager/lima-host.nix
              ./home-manager/systemd.nix
              ./home-manager/gnome.nix
              ./home-manager/firefox.nix
            ];
          };

          "kachick@wsl-ubuntu" = home-manager-linux.lib.homeManagerConfiguration {
            pkgs = x86-Linux-pkgs;
            modules = [
              ./home-manager/kachick.nix
              ./home-manager/linux.nix
              ./home-manager/genericLinux.nix
              ./home-manager/wsl.nix
            ];
          };

          "nixos@wsl-nixos" = home-manager-linux.lib.homeManagerConfiguration {
            pkgs = x86-Linux-pkgs;
            modules = [
              ./home-manager/kachick.nix
              ./home-manager/linux.nix
              {
                home.username = "nixos";
                targets.genericLinux.enable = false;
              }
              ./home-manager/wsl.nix
            ];
          };

          "kachick@macbook" = home-manager-darwin.lib.homeManagerConfiguration {
            pkgs = x86-macOS-pkgs;
            modules = [
              ./home-manager/kachick.nix
              ./home-manager/darwin.nix
            ];
          };

          "kachick@lima" = home-manager-darwin.lib.homeManagerConfiguration {
            pkgs = x86-Linux-pkgs;
            modules = [
              ./home-manager/kachick.nix
              ./home-manager/linux.nix
              ./home-manager/genericLinux.nix
              ./home-manager/lima-guest.nix
            ];
          };

          "github-actions@ubuntu-24.04" = home-manager-linux.lib.homeManagerConfiguration {
            pkgs = x86-Linux-pkgs;
            # Prefer "kachick" over "common" only here.
            # Using values as much as possible as actual values to create a robust CI
            modules = [
              ./home-manager/kachick.nix
              ./home-manager/linux.nix
              { home.username = "runner"; }
              ./home-manager/genericLinux.nix
              ./home-manager/systemd.nix
            ];
          };

          "github-actions@macos-13" = home-manager-darwin.lib.homeManagerConfiguration {
            pkgs = x86-macOS-pkgs;
            # Prefer "kachick" over "common" only here.
            # Using values as much as possible as actual values to create a robust CI
            modules = [
              ./home-manager/kachick.nix
              ./home-manager/darwin.nix
              { home.username = "runner"; }
            ];
          };

          "user@linux-cli" = home-manager-linux.lib.homeManagerConfiguration {
            pkgs = x86-Linux-pkgs;
            modules = [
              ./home-manager/common.nix
              { home.username = "user"; }
              ./home-manager/linux.nix
              ./home-manager/genericLinux.nix
              ./home-manager/systemd.nix
            ];
          };
        };
    };
}

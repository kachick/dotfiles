{
  description = "kachick's dotfiles that can be placed in the public repository";

  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    # darwin does not have desirable channel for that purpose. See https://github.com/NixOS/nixpkgs/issues/107466
    edge-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    # https://github.com/nix-community/home-manager/blob/release-24.11/docs/manual/nix-flakes.md
    home-manager-linux = {
      # Using forked repository because of to apply https://github.com/nix-community/home-manager/pull/6357 in stable channel
      # See https://github.com/kachick/dotfiles/issues/1051 for detail
      url = "github:kachick/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-darwin = {
      url = "github:kachick/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main"; # TODO: Pin to 2411.?.? if 24.11 compat channel will be introduced
      # https://github.com/nix-community/NixOS-WSL/blob/5a965cb108fb1f30b29a26dbc29b473f49e80b41/flake.nix#L5
      inputs.nixpkgs.follows = "nixpkgs";
    };
    selfup = {
      url = "github:kachick/selfup/v1.1.9";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    psfeditor = {
      # https://github.com/ideras/PSFEditor/pull/1
      url = "github:ideras/PSFEditor";
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
      # Useable with filepaths. Don't use `nix fmt` and use `treefmt`. See https://github.com/NixOS/nixfmt/commit/ba0c3fa3da27a2815026bc4ea0216e10f1c50542
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
                go-task
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
                  typos
                  typos-lsp # For zed-editor typos extension
                  go_1_23
                  trivy
                  markdownlint-cli2

                  (ruby_3_4.withPackages (ps: with ps; [ rubocop ]))
                ])
                ++ (with pkgs.unstable; [
                  trufflehog
                  # https://github.com/NixOS/nixpkgs/pull/362139
                  dprint
                  lychee
                ])
                ++ (with pkgs.my; [ nix-hash-url ])
                ++ [
                  inputs.selfup.packages.${system}.default
                  inputs.psfeditor.packages.${system}.default
                ]
              ));
          };
        }
      );

      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        # pkgs.my // pkgs.patched # TODO: Adding another name space will fail, and nix flake check fails if it including unfree
        pkgs.my
      );

      apps = forAllSystems (system: {
        home-manager = mkApp {
          inherit system;
          pkg = (mkHomeManager system).defaultPackage.${system};
        };
      });

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
              ./home-manager/desktop.nix
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

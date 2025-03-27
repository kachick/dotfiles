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
      url = "github:nix-community/NixOS-WSL/2411.6.0";
      # https://github.com/nix-community/NixOS-WSL/blob/2411.6.0/flake.nix#L5
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
          # Keeping latest would be better with below reasons
          # - typos-lsp is a third-party tool, it might have different releases with typos-cli even in same Nix channel.
          #   See https://github.com/kachick/dotfiles/commit/11bd10a13196d87f74f9464964d34f6ce33fa669#commitcomment-154399068 for detail.
          # - It will not be used in CI, it dont not block workflows even if typos upstream introduced false-positive detection
          typos-lsp = pkgs.unstable.typos-lsp;
        in
        {
          default = pkgs.mkShellNoCC {
            # Realize nixd pkgs version inlay hints for stable channel instead of latest
            NIX_PATH = "nixpkgs=${pkgs.path}";

            TYPOS_LSP_PATH = pkgs.lib.getExe typos-lsp; # For vscode typos extension

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

                  shellcheck
                  shfmt

                  # Don't use treefmt(treefmt1) that does not have crucial feature to cover hidden files
                  # https://github.com/numtide/treefmt/pull/250
                  treefmt2
                  typos
                  trivy
                  markdownlint-cli2
                ])
                ++ (with pkgs.unstable; [
                  hydra-check # Background and how to use: https://github.com/kachick/dotfiles/pull/909#issuecomment-2453389909
                  # https://github.com/NixOS/nixpkgs/pull/362139
                  gitleaks # TODO: Consider to replace to stable since nixos-25.05. nixos-24.11 including version makes false-positive error now
                  dprint
                  lychee
                  go_1_24
                ])
                ++ (with pkgs.my; [ nix-hash-url ])
                ++ [
                  typos-lsp # For zed-editor typos extension
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
        # Don't include unfree packages, it will fail in `nix flake check`
        pkgs.lib.recursiveUpdate pkgs.patched pkgs.my
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
              ./home-manager/linux-ci.nix
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

          "user@container" = home-manager-linux.lib.homeManagerConfiguration {
            pkgs = x86-Linux-pkgs;
            modules = [
              ./home-manager/genericUser.nix
              ./home-manager/linux.nix
              ./home-manager/genericLinux.nix
              ./home-manager/systemd.nix
            ];
          };
        };
    };
}

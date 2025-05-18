{
  description = "kachick's dotfiles that can be placed in the public repository";

  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # darwin does not have desirable channel for that purpose. See https://github.com/NixOS/nixpkgs/issues/107466
    edge-nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    home-manager-linux = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main"; # TODO: Use 2505.n.n if available
      # https://github.com/nix-community/NixOS-WSL/blob/2411.6.0/flake.nix#L5
      inputs.nixpkgs.follows = "nixpkgs";
    };
    psfeditor = {
      # https://github.com/ideras/PSFEditor/pull/1
      # Update this if the status of https://github.com/NixOS/nixpkgs/pull/396886 be changed
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
          "x86_64-darwin" # Kept for actual my device
          "aarch64-darwin" # Kept for GHA macos-14 or later. macos-13 is deadly slow for daily CI
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
        if (nixpkgs.lib.strings.hasSuffix "-darwin" system) then # ... correct code?
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
      # Why not use `nixfmt-rfc-style`: https://github.com/NixOS/nixpkgs/pull/384857
      formatter = forAllSystems (system: (mkPkgs system).nixfmt-tree);

      devShells = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          # Keeping latest would be better with below reasons
          # - typos-lsp is a third-party tool, it might have different releases with typos-cli even if both are defined in same nixpkgs channel.
          #   See https://github.com/kachick/dotfiles/commit/11bd10a13196d87f74f9464964d34f6ce33fa669#commitcomment-154399068 for detail.
          # - It will not be used in CI, it doesn't block workflows even if typos upstream introduced false-positive detection.
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
                  nixpkgs-lint-community
                  nixd
                  nixf # `nixf-tidy`
                  nix-init
                  nurl
                  nixfmt-rfc-style

                  go_1_24

                  shellcheck
                  shfmt

                  # We don't need to consider about treefmt1 https://github.com/NixOS/nixpkgs/pull/387745
                  treefmt

                  typos
                  trivy
                  markdownlint-cli2
                  lychee
                ])
                ++ (with pkgs.unstable; [
                  hydra-check # Background and how to use: https://github.com/kachick/dotfiles/pull/909#issuecomment-2453389909
                  gitleaks
                  dprint
                ])
                ++ (with pkgs.my; [ nix-hash-url ])
                ++ [
                  typos-lsp # For zed-editor typos extension
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
          pkg = (mkHomeManager system).packages.${system}.home-manager;
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
          "generic" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./nixos/hosts/generic ]; });
          "wsl" = nixpkgs.lib.nixosSystem (shared // { modules = [ ./nixos/hosts/wsl ]; });
        };

      homeConfigurations =
        let
          x86-Linux-pkgs = mkPkgs "x86_64-linux";
        in
        {
          "kachick@wsl-ubuntu" = home-manager-linux.lib.homeManagerConfiguration {
            pkgs = x86-Linux-pkgs;
            modules = [
              ./home-manager/kachick.nix
              ./home-manager/linux.nix
              ./home-manager/genericLinux.nix
              ./home-manager/wsl.nix
            ];
          };

          "kachick@macbook" = home-manager-darwin.lib.homeManagerConfiguration {
            pkgs = mkPkgs "x86_64-darwin";
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

          # macos-13 is the latest x86-64 runner for darwin and technically the right choice for respecting architecture of my old MacBook,
          # but it's slow, almost 3x slower than Linux runners - so I prefer macos-14 or later. :<
          #
          # From another angle, I do keep my MacBook OS up-to-date, so maybe it's actually more appropriate as a CI environment than macos-13.
          # Ideally, I guess it would be best to run both macos-13 and "macos-latest or later"(actually not "latest" in GitHub!),
          # but I spend less than 1% of my time on macOS compared to Linux, so I don't want to make things more complex here.
          "github-actions@macos-15" = home-manager-darwin.lib.homeManagerConfiguration {
            pkgs = mkPkgs "aarch64-darwin";
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

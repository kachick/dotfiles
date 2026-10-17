{
  description = "kachick's dotfiles that can be placed in the public repository";

  nixConfig = {
    extra-substituters = [
      "https://cache.kachick.dev"
      "https://kachick.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.kachick.dev-1:qxT+mjqH5A1VvQ/piD14E7heonmzkIPvati+dndwYFY="
      "kachick.cachix.org-1:7giZGKW03gPFkbde09JNpDKCbDGGwBuU/Z11W/jUtEQ="
    ];
  };

  inputs = {
    # Why prefer channels.nixos.org rather than GitHub?
    #   - Avoid rate limit
    #   - nixos.org distributing tar.xz is smaller than GitHub's zip
    #   - nixos.org distributing tar.xz might ensure stable binary caches
    # See https://github.com/kachick/dotfiles/issues/1262#issuecomment-3302717297 for details
    #
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.zst";
    nixpkgs-unstable.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    home-manager-linux = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };

    kanata-tray = {
      url = "github:kachick/kanata-tray/96e686c7f04db4f0f7ca178a0c5e374c4bb2baff";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    selfup = {
      url = "github:kachick/selfup/v1.3.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager-linux,
      kanata-tray,
      selfup,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      overlays = import ./overlays {
        inherit
          nixpkgs-unstable
          kanata-tray
          home-manager-linux
          selfup
          ;
      };

      mkPkgs = system: import nixpkgs { inherit system overlays; };

      # Candidates: https://github.com/NixOS/nixpkgs/blob/nixos-26.05/lib/systems/flake-systems.nix
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs
          (nixpkgs.lib.intersectLists [ "x86_64-linux" ] nixpkgs.lib.systems.flakeExposed)
          (
            system:
            f {
              inherit system;
              pkgs = mkPkgs system;
            }
          );
    in
    {
      formatter = forAllSystems (
        { pkgs, ... }:
        pkgs.writeShellScriptBin "dprint-fmt" ''
          exec "${pkgs.lib.getExe pkgs.unstable.dprint}" fmt "$@"
        ''
      );

      devShells = forAllSystems ({ pkgs, ... }: import ./devShells.nix { inherit pkgs; });

      packages = forAllSystems (
        { pkgs, ... }:
        # Don't include unfree packages, it will fail in `nix flake check`
        pkgs.lib.recursiveUpdate pkgs.pinned pkgs.local
      );

      apps = forAllSystems (
        { pkgs, system }:
        {
          home-manager = {
            type = "app";
            program = pkgs.lib.getExe home-manager-linux.packages.${system}.home-manager;
          };
          gen-nix-cache-conf = {
            type = "app";
            program = pkgs.lib.getExe pkgs.local.gen-nix-cache-conf;
          };
          niks3 = {
            type = "app";
            program = pkgs.lib.getExe' pkgs.niks3 "niks3";
          };
          list-shared-gomod-pkgs = {
            type = "app";
            program =
              let
                script = pkgs.writeShellScriptBin "list-shared-gomod-pkgs" ''
                  ${pkgs.lib.getExe pkgs.unstable.nix} eval --raw ".#packages.${system}" --apply 'ps: builtins.concatStringsSep "\n" (builtins.filter (n: ps.''${n}.passthru.shared-gomod or false) (builtins.attrNames ps))'
                '';
              in
              pkgs.lib.getExe script;
          };
        }
      );

      nixosConfigurations = import ./nixos {
        inherit
          nixpkgs
          inputs
          outputs
          overlays
          ;
      };

      homeConfigurations = import ./home-manager {
        inherit
          home-manager-linux
          mkPkgs
          outputs
          ;
      };

      overlays = {
        default = nixpkgs.lib.composeManyExtensions overlays;
      };

      nixosModules = import ./nixos/modules { inherit inputs; };

      homeManagerModules = import ./home-manager/modules { inherit overlays; };
    };
}

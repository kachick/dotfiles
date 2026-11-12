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
    #   - Run `task update` instead of direct `nix flake update` to keep transitive follows deduplicated via flake-edit
    #
    # Why track only rolling release?: https://github.com/kachick/dotfiles/issues/1787
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Why prefer tracking the default branch rather than a release tag?
    # Upstream (astro/microvm-nix) has not issued any new git tags since v0.5.0 in April 2024.
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };

    kanata-tray = {
      url = "github:kachick/kanata-tray/cgo-disabled";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ghadiag = {
      url = "github:kachick/ghadiag";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cntr = {
      url = "github:Mic92/cntr/2.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "";
      inputs.fenix.follows = "";
    };

    iets = {
      url = "github:numtide/iets/v0.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      kanata-tray,
      ghadiag,
      cntr,
      iets,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      overlays = import ./overlays {
        inherit
          kanata-tray
          ghadiag
          cntr
          iets
          home-manager
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
          exec "${pkgs.lib.getExe pkgs.dprint}" fmt "$@"
        ''
      );

      devShells = forAllSystems ({ pkgs, ... }: import ./devShells.nix { inherit pkgs; });

      packages = forAllSystems (
        { pkgs, system }:
        # Don't include unfree packages, it will fail in `nix flake check`
        (pkgs.lib.recursiveUpdate pkgs.pinned pkgs.local)
        // {
          container-layered = import ./containers/layered-image.nix {
            inherit pkgs;
            homeConfigurations = outputs.homeConfigurations;
            corePackages = outputs.nixosConfigurations.installer.config.environment.corePackages;
          };
        }
        // (pkgs.lib.optionalAttrs (system == "x86_64-linux") {
          microvm-sandbox =
            pkgs.runCommand "microvm-sandbox"
              {
                meta.mainProgram = "microvm-sandbox";
              }
              ''
                mkdir -p $out/bin
                ln -s ${outputs.nixosConfigurations.sandbox.config.microvm.declaredRunner}/bin/microvm-run $out/bin/microvm-sandbox
              '';
        })
      );

      apps = forAllSystems (
        { pkgs, system }:
        {
          home-manager = {
            type = "app";
            program = pkgs.lib.getExe home-manager.packages.${system}.home-manager;
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
                  ${pkgs.lib.getExe pkgs.nix} eval --raw ".#packages.${system}" --apply 'ps: builtins.concatStringsSep "\n" (builtins.filter (n: ps.''${n}.passthru.shared-gomod or false) (builtins.attrNames ps))'
                '';
              in
              pkgs.lib.getExe script;
          };
          microvm-sandbox = {
            type = "app";
            program = pkgs.lib.getExe outputs.packages.${system}.microvm-sandbox;
          };
          flake-edit = {
            type = "app";
            program = pkgs.lib.getExe pkgs.flake-edit;
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
          home-manager
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

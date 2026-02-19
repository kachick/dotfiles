{
  description = "kachick's dotfiles that can be placed in the public repository";

  nixConfig = {
    extra-substituters = [
      "https://kachick-dotfiles.cachix.org"
    ];
    extra-trusted-public-keys = [
      "kachick-dotfiles.cachix.org-1:XhiP3JOkqNFGludaN+/send30shcrn1UMDeRL9XttkI="
    ];
  };

  inputs = {
    # Why prefer channels.nixos.org rather than GitHub?
    #   - Avoid rate limit
    #   - nixos.org distributing tar.xz is smaller than GitHub's zip
    #   - nixos.org distributing tar.xz might ensure stable binary caches
    # See https://github.com/kachick/dotfiles/issues/1262#issuecomment-3302717297 for detail
    #
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "https://channels.nixos.org/nixos-25.11/nixexprs.tar.xz";
    # darwin does not have desirable channel for that purpose. See https://github.com/NixOS/nixpkgs/issues/107466
    nixpkgs-unstable.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    nixpkgs-darwin.url = "https://channels.nixos.org/nixpkgs-25.11-darwin/nixexprs.tar.xz";
    home-manager-linux = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager-darwin = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat = {
      url = "github:NixOS/flake-compat";
      flake = false;
    };

    kanata-tray = {
      # TODO: Prefer https://github.com/NixOS/nixpkgs/pull/458994 once it's in a suitable channel.
      url = "github:rszyma/kanata-tray/v0.8.0";

      # This repo provides binary cache since 0.7.1: https://github.com/rszyma/kanata-tray/commit/f506a3d653a08affdf1f2f9c6f2d0d44181dc92b.
      # However using follows disables the upstream caches. And I'm okay to build it my self
      # Prefer unstable channel since also using latest kanata
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-darwin,
      home-manager-linux,
      home-manager-darwin,
      kanata-tray,
      ...
    }@inputs:
    let
      inherit (self) outputs;

      # Candidates: https://github.com/NixOS/nixpkgs/blob/nixos-25.11/lib/systems/flake-systems.nix
      forAllSystems = nixpkgs.lib.genAttrs (
        nixpkgs.lib.intersectLists [
          "x86_64-linux"
          "x86_64-darwin"
        ] nixpkgs.lib.systems.flakeExposed
      );

      mkNixpkgs =
        system: if (nixpkgs.lib.strings.hasSuffix "-darwin" system) then nixpkgs-darwin else nixpkgs;

      overlays = import ./overlays {
        inherit
          nixpkgs-unstable
          kanata-tray
          home-manager-linux
          home-manager-darwin
          ;
      };

      mkPkgs = system: import (mkNixpkgs system) { inherit system overlays; };

      mkApp =
        { system, pkg }:
        {
          type = "app";
          program = (mkNixpkgs system).lib.getExe pkg;
        };
    in
    {
      # Why not use `nixfmt`: https://github.com/NixOS/nixpkgs/pull/384857
      formatter = forAllSystems (system: (mkPkgs system).unstable.nixfmt-tree);

      devShells = forAllSystems (system: import ./devShells.nix { pkgs = mkPkgs system; });

      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
          # Don't include unfree packages, it will fail in `nix flake check`
        in
        pkgs.lib.recursiveUpdate pkgs.patched pkgs.my
      );

      apps = forAllSystems (system: {
        home-manager = mkApp {
          inherit system;
          pkg = (mkPkgs system).home-manager;
        };
      });

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
          home-manager-darwin
          mkPkgs
          outputs
          ;
      };

      overlays = {
        default = nixpkgs.lib.composeManyExtensions overlays;
      };

      nixosModules = {
        common = ./nixos/configuration.nix;
        hardware = ./nixos/hardware.nix;
        desktop = ./nixos/modules/desktop.nix;
      };

      homeManagerModules = {
        common = ./home-manager/common.nix;
        desktop = ./home-manager/modules/desktop.nix;
        # All Linux (NixOS + non-NixOS)
        linux = ./home-manager/linux.nix;
        # Only for non-NixOS Linux (Home Manager convention)
        genericLinux = ./home-manager/genericLinux.nix;

        # Personal profile
        kachick = ./home-manager/modules/kachick.nix;

        # Platform/Environment specific
        genericUser = ./home-manager/genericUser.nix;
        darwin = ./home-manager/darwin.nix;
        systemd = ./home-manager/systemd.nix;
        wsl = ./home-manager/wsl.nix;
        lima-guest = ./home-manager/lima-guest.nix;
        lima-host = ./home-manager/lima-host.nix;
        overlays = {
          nixpkgs.overlays = [ self.overlays.default ];
        };
      };
    };
}

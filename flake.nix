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

    llm-agents = {
      url = "github:numtide/llm-agents.nix";

      # This repo provides binary cache and I already allows the cache.numtide.com.
      # However, to reduce nodes in flake.lock, I prefer my own channel for now.
      # Revisit once introducing other agents which takes long time to build.
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      nixpkgs-unstable,
      nixpkgs-darwin,
      home-manager-linux,
      home-manager-darwin,
      kanata-tray,
      llm-agents,
      flake-parts,
      ...
    }:
    let
      sharedOverlays =
        (import ./overlays {
          inherit
            nixpkgs-unstable
            kanata-tray
            home-manager-linux
            home-manager-darwin
            ;
        })
        ++ [ llm-agents.overlays.default ];

      mkPkgs =
        system:
        let
          base = if (nixpkgs.lib.strings.hasSuffix "-darwin" system) then nixpkgs-darwin else nixpkgs;
        in
        import base {
          inherit system;
          overlays = sharedOverlays;
        };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
      ];

      # Modularize the flake by importing parts.
      # These files will automatically receive 'self', 'inputs', and 'mkPkgs' as arguments.
      imports = [
        ./nixos
        ./home-manager
        ./home-manager/modules
      ];

      _module.args = {
        inherit nixpkgs mkPkgs sharedOverlays;
      };

      perSystem =
        {
          system,
          ...
        }:
        let
          pkgs = mkPkgs system;
        in
        {
          # Why not use `nixfmt`: https://github.com/NixOS/nixpkgs/pull/384857
          formatter = pkgs.unstable.nixfmt-tree;

          devShells = import ./devShells.nix { inherit pkgs; };

          packages = pkgs.lib.recursiveUpdate pkgs.pinned pkgs.local;

          apps = {
            home-manager = {
              type = "app";
              program = nixpkgs.lib.getExe pkgs.home-manager;
            };
            gen-nix-cache-conf = {
              type = "app";
              program = nixpkgs.lib.getExe pkgs.local.gen-nix-cache-conf;
            };
          };
        };

      flake = {
        overlays = {
          # Consolidated overlay exposed as a primary flake output.
          default = nixpkgs.lib.composeManyExtensions sharedOverlays;
        };

        nixosModules = import ./nixos/modules { inherit inputs; };
      };
    };
}

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
    # https://github.com/xremap/nix-flake/blob/master/docs/HOWTO.md
    xremap-flake.url = "github:xremap/nix-flake";
    # https://github.com/wez/wezterm/pull/3547#issuecomment-1915820504
    wezterm-flake.url = "github:wez/wezterm?dir=nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      edge-nixpkgs,
      home-manager,
      xremap-flake,
      wezterm-flake,
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

      packages = forAllSystems (
        system:
        (import ./pkgs {
          pkgs = nixpkgs.legacyPackages.${system};
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
            mkShell {
              buildInputs = [
                # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
                bashInteractive
                nixfmt-rfc-style
                nil
                nixpkgs-lint-community
                # To get sha256 around pkgs.fetchFromGitHub in CLI
                nix-prefetch-git
                jq

                shellcheck
                shfmt
                gitleaks
                cargo-make

                dprint
                # TODO: Use stable if https://github.com/google/yamlfmt/pull/179 is released
                edge-pkgs.yamlfmt
                stylua
                typos
                typos-lsp
                go_1_22
                goreleaser
                trivy
              ];
            };
        }
      );

      apps = forAllSystems (system: {
        # example: `nix run .#home-manager -- switch -n -b backup --flake .#user@linux`
        # https://github.com/NixOS/nix/issues/6448#issuecomment-1132855605
        home-manager = mkApp home-manager.defaultPackage.${system};
        bump_completions = mkApp packages.${system}.check_no_dirty_xz_in_nix_store;
        check_no_dirty_xz_in_nix_store = mkApp packages.${system}.check_no_dirty_xz_in_nix_store;
        bench_shells = mkApp packages.${system}.bench_shells;
        walk = mkApp packages.${system}.walk;
        todo = mkApp packages.${system}.todo;
        la = mkApp packages.${system}.la;
        lat = mkApp packages.${system}.lat;
        ghqf = mkApp packages.${system}.ghqf;
        git-delete-merged-branches = mkApp packages.${system}.git-delete-merged-branches;
        git-log-fzf = mkApp packages.${system}.git-log-fzf;
        prs = mkApp packages.${system}.prs;
      });

      nixosConfigurations =
        let
          system = "x86_64-linux";
          edge-pkgs = import edge-nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };
          homemade-pkgs = packages.${system};
        in
        {
          "nixos-desktop" = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              ./nixos/configuration.nix
              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "backup";
                  users.kachick = import ./home-manager/kachick.nix;

                  extraSpecialArgs = {
                    inherit homemade-pkgs edge-pkgs;
                  };
                };
              }
              {
                # Only add unfree packages definitions here
                home-manager.users.kachick.programs = {
                  # https://github.com/nix-community/home-manager/blob/release-24.05/modules/programs/chromium.nix
                  google-chrome = {
                    enable = true;
                    # https://wiki.archlinux.org/title/Chromium#Native_Wayland_support
                    commandLineArgs = [ "--enable-wayland-ime" ];
                  };
                };
              }
              xremap-flake.nixosModules.default
              {
                # Modmap for single key rebinds
                services.xremap.config = {
                  modmap = [
                    {
                      name = "Global";
                      remap = {
                        "CapsLock" = "Ctrl_L";
                        "Alt_L" = {
                          "held" = "Alt_L";
                          "alone" = "Muhenkan";
                          "alone_timeout_millis" = 500;
                        };
                        "Alt_R" = "Henkan";
                      };
                    }
                  ];

                  # Keymap for key combo rebinds
                  keymap = [
                    {
                      name = "Gnome lancher";
                      remap = {
                        "Alt-Space" = "LEFTMETA";
                      };
                    }
                  ];
                };
              }
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
        };

      homeConfigurations = {
        "kachick@linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [ ./home-manager/kachick.nix ];
          extraSpecialArgs = {
            homemade-pkgs = packages.x86_64-linux;
            edge-pkgs = edge-nixpkgs.legacyPackages.x86_64-linux;
          };
        };

        "kachick@wsl" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home-manager/kachick.nix
            ./home-manager/wsl.nix
          ];
          extraSpecialArgs = {
            homemade-pkgs = packages.x86_64-linux;
            edge-pkgs = edge-nixpkgs.legacyPackages.x86_64-linux;
          };
        };

        "kachick@macbook" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-darwin;
          modules = [ ./home-manager/kachick.nix ];
          extraSpecialArgs = {
            homemade-pkgs = packages.x86_64-darwin;
            edge-pkgs = edge-nixpkgs.legacyPackages.x86_64-darwin;
          };
        };

        "github-actions@ubuntu-24.04" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            # Prefer "kachick" over "common" only here.
            # Using values as much as possible as actual values to create a robust CI
            ./home-manager/kachick.nix
            { home.username = "runner"; }
          ];
          extraSpecialArgs = {
            homemade-pkgs = packages.x86_64-linux;
            edge-pkgs = edge-nixpkgs.legacyPackages.x86_64-linux;
          };
        };

        "github-actions@macos-14" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.aarch64-darwin;
          modules = [
            # Prefer "kachick" over "common" only here.
            # Using values as much as possible as actual values to create a robust CI
            ./home-manager/kachick.nix
            { home.username = "runner"; }
          ];
          extraSpecialArgs = {
            homemade-pkgs = packages.aarch64-darwin;
            edge-pkgs = edge-nixpkgs.legacyPackages.aarch64-darwin;
          };
        };

        "user@linux" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
          modules = [
            ./home-manager/common.nix
            { home.username = "user"; }
          ];
          extraSpecialArgs = {
            homemade-pkgs = packages.x86_64-linux;
            edge-pkgs = edge-nixpkgs.legacyPackages.x86_64-linux;
          };
        };
      };
    };
}

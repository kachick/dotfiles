{
  inputs = {
    # Candidate channels
    #   - https://github.com/kachick/anylang-template/issues/17
    #   - https://discourse.nixos.org/t/differences-between-nix-channels/13998
    # How to update the revision
    #   - `nix flake update --commit-lock-file` # https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-update.html
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # https://github.com/nix-community/home-manager/blob/master/docs/nix-flakes.adoc
    home-manager = {
      # candidates: "github:nix-community/home-manager/release-23.05";
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, flake-utils } @ inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          # inherit (self) outputs;
          pkgs = nixpkgs.legacyPackages.${system};
          unstable-packages = nixpkgs-unstable.legacyPackages.${system};
        in
        rec {
          overlays = import ./overlays { inherit inputs; };

          devShells.default = with pkgs;
            mkShell {
              buildInputs = [
                # https://github.com/NixOS/nix/issues/730#issuecomment-162323824
                bashInteractive

                unstable-packages.dprint
                shellcheck
                shfmt
                nil
                nixpkgs-fmt
                gitleaks
                cargo-make
                unstable-packages.typos
                unstable-packages.go_1_21
                goreleaser

                # To get sha256 around pkgs.fetchFromGitHub in CLI
                nix-prefetch-git
                jq
              ];
            };

          packages.homeConfigurations =
            {
              kachick = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = [
                  ./home-manager/home.nix
                ];
              };

              github-actions = home-manager.lib.homeManagerConfiguration {
                inherit pkgs;
                modules = [
                  ./home-manager/home.nix
                  {
                    home.username = "runner";
                  }
                ];
              };
            };

          packages.enable_nix_login_shells = pkgs.stdenv.mkDerivation
            {
              name = "enable_nix_login_shells";
              src = self;
              buildInputs = with pkgs; [
                go_1_21
              ];
              buildPhase = ''
                # https://github.com/NixOS/nix/issues/670#issuecomment-1211700127
                export HOME=$(pwd)
                go build -o dist/enable_nix_login_shells ./cmd/enable_nix_login_shells
              '';
              installPhase = ''
                mkdir -p $out/bin
                install -t $out/bin dist/enable_nix_login_shells
              '';
            };

          packages.sudo_enable_nix_login_shells = pkgs.writeScriptBin "sudo_enable_nix_login_shells" ''
            sudo -E ${packages.enable_nix_login_shells}/bin/enable_nix_login_shells
          '';

          # https://gist.github.com/Scoder12/0538252ed4b82d65e59115075369d34d?permalink_comment_id=4650816#gistcomment-4650816
          packages.json2nix = pkgs.writeScriptBin "json2nix" ''
            ${pkgs.python3}/bin/python ${pkgs.fetchurl {
              url = "https://gist.githubusercontent.com/Scoder12/0538252ed4b82d65e59115075369d34d/raw/e86d1d64d1373a497118beb1259dab149cea951d/json2nix.py";
              hash = "sha256-ROUIrOrY9Mp1F3m+bVaT+m8ASh2Bgz8VrPyyrQf9UNQ=";
            }} $@
          '';

          apps = {
            # example: `nix run .#home-manager -- switch -n -b backup --flake .#kachick`
            # https://github.com/NixOS/nix/issues/6448#issuecomment-1132855605
            home-manager = flake-utils.lib.mkApp {
              drv = home-manager.defaultPackage.${system};
            };

            sudo_enable_nix_login_shells = {
              type = "app";
              program = "${packages.sudo_enable_nix_login_shells}/bin/sudo_enable_nix_login_shells";
            };

            # example: `nix run .#json2nix gitconfig.json`
            json2nix = {
              type = "app";
              program = "${packages.json2nix}/bin/json2nix";
            };
          };
        }
      );
}


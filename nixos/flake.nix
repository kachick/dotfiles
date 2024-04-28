{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-23.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    # unstable-pkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # https://github.com/xremap/nix-flake/blob/master/docs/HOWTO.md
    xremap-flake.url = "github:xremap/nix-flake";
  };

  outputs =
    {
      self,
      nixpkgs,
      # unstable-pkgs,
      xremap-flake,
      ...
    }@inputs:
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # specialArgs = {
        #   inherit unstable-pkgs;
        # };
        modules = [
          # Import the previous configuration.nix we used,
          # so the old configuration file still takes effect
          ./configuration.nix
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
      };
    };
}

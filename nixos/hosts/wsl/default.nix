{ inputs, ... }:

{
  networking.hostName = "wsl";

  imports = [
    ../../configuration.nix
    inputs.nixos-wsl.nixosModules.default
  ];

  wsl.enable = true;

  # wsl.defaultUser is `nixos`

  # Do not set `boot.loader.systemd-boot.enable` to avoid conflict between following modules
  #   - https://github.com/nix-community/NixOS-WSL/blob/f373ad59ae5866f0f98216bd5c71526b373450d2/modules/wsl-distro.nix#L69
  #   - https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/system/boot/loader/systemd-boot/systemd-boot.nix#L416C33-L416C56

  # Required to run VSCode Remote server
  programs.nix-ld = {
    enable = true;
  };

  home-manager = {
    # useGlobalPkgs = true;
    # useUserPackages = true;
    backupFileExtension = "backup";
    users.kachick = {
      imports = [
        ../../home-manager/kachick.nix
        ../../home-manager/linux.nix
        {
          home.username = "nixos";
          targets.genericLinux.enable = false;
        }
        ../../home-manager/wsl.nix
      ];
    };
    # extraSpecialArgs = {
    #   inherit
    #     inputs
    #     ;
    # };
  };
}

{
  home-manager,
  mkPkgs,
  outputs,
}:

let
  x86-Linux-pkgs = mkPkgs "x86_64-linux";
  shared = {
    extraSpecialArgs = {
      inherit outputs;
    };
  };
in
# Users on NixOS are separated from this file.
{
  "visitor@wsl-ubuntu" = home-manager.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = x86-Linux-pkgs;
      modules = [
        outputs.homeManagerModules.kachick # Intentionally use a specific user config in WSL despite using the ephemeral "visitor" username
        {
          home.username = "visitor"; # Enforce the ephemeral "visitor" username
        }
        outputs.homeManagerModules.linux
        outputs.homeManagerModules.genericLinux
        outputs.homeManagerModules.wsl
        outputs.homeManagerModules.storage
        outputs.homeManagerModules.messenger
        outputs.homeManagerModules.containers
      ];
    }
  );

  "visitor@lima" = home-manager.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = x86-Linux-pkgs;
      modules = [
        outputs.homeManagerModules.ephemeral
        outputs.homeManagerModules.linux
        outputs.homeManagerModules.genericLinux
        outputs.homeManagerModules.lima-guest
        outputs.homeManagerModules.storage
        outputs.homeManagerModules.messenger
        outputs.homeManagerModules.containers
      ];
    }
  );

  "visitor@container" = home-manager.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = x86-Linux-pkgs;
      modules = [
        outputs.homeManagerModules.ephemeral
        outputs.homeManagerModules.linux
        outputs.homeManagerModules.genericLinux
        outputs.homeManagerModules.systemd
        outputs.homeManagerModules.storage
        outputs.homeManagerModules.messenger
      ];
    }
  );

  "github-actions@ubuntu-26.04" = home-manager.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = x86-Linux-pkgs;
      modules = [
        outputs.homeManagerModules.kachick
        outputs.homeManagerModules.linux
        outputs.homeManagerModules.genericLinux
        { home.username = "runner"; }
        outputs.homeManagerModules.systemd
      ];
    }
  );
}

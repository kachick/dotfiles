{
  home-manager-linux,
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
  "user@wsl-ubuntu" = home-manager-linux.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = x86-Linux-pkgs;
      modules = [
        outputs.homeManagerModules.kachick # Intentionally use a specific user config in WSL despite using the ephemeral "user" username
        {
          home.username = "user"; # Enforce the ephemeral "user" username
        }
        outputs.homeManagerModules.linux
        outputs.homeManagerModules.genericLinux
        outputs.homeManagerModules.wsl
      ];
    }
  );

  "user@lima" = home-manager-linux.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = x86-Linux-pkgs;
      modules = [
        outputs.homeManagerModules.ephemeral
        outputs.homeManagerModules.linux
        outputs.homeManagerModules.genericLinux
        outputs.homeManagerModules.lima-guest
      ];
    }
  );

  "user@container" = home-manager-linux.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = x86-Linux-pkgs;
      modules = [
        outputs.homeManagerModules.ephemeral
        outputs.homeManagerModules.linux
        outputs.homeManagerModules.genericLinux
        outputs.homeManagerModules.systemd
      ];
    }
  );

  "github-actions@ubuntu-26.04" = home-manager-linux.lib.homeManagerConfiguration (
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

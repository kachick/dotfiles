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
  "kachick@wsl-ubuntu" = home-manager-linux.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = x86-Linux-pkgs;
      modules = [
        outputs.homeManagerModules.kachick
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

  "github-actions@ubuntu-24.04" = home-manager-linux.lib.homeManagerConfiguration (
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

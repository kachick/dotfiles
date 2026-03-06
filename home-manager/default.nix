{
  home-manager-linux,
  home-manager-darwin,
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
{
  "kachick@wsl-ubuntu" = home-manager-linux.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = x86-Linux-pkgs;
      modules = [
        outputs.homeManagerModules.profiles.kachick
        outputs.homeManagerModules.targets.linux
        outputs.homeManagerModules.targets.generic-linux
        outputs.homeManagerModules.targets.wsl
      ];
    }
  );

  "kachick@macbook" = home-manager-darwin.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = mkPkgs "x86_64-darwin";
      modules = [
        outputs.homeManagerModules.profiles.kachick
        outputs.homeManagerModules.targets.darwin
      ];
    }
  );

  # Lima guest username is forced to match the host username by design.
  # Revisit once https://github.com/lima-vm/lima/issues/1015 has resolved
  "kachick@lima" = home-manager-linux.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = x86-Linux-pkgs;
      modules = [
        outputs.homeManagerModules.profiles.kachick
        outputs.homeManagerModules.targets.linux
        outputs.homeManagerModules.targets.generic-linux
        outputs.homeManagerModules.targets.lima-guest
      ];
    }
  );

  "github-actions@ubuntu-24.04" = home-manager-linux.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = x86-Linux-pkgs;
      modules = [
        outputs.homeManagerModules.profiles.kachick
        outputs.homeManagerModules.targets.linux
        outputs.homeManagerModules.targets.generic-linux
        { home.username = "runner"; }
        outputs.homeManagerModules.services.systemd
      ];
    }
  );

  "github-actions@macos-15-intel" = home-manager-darwin.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = mkPkgs "x86_64-darwin";
      modules = [
        outputs.homeManagerModules.profiles.kachick
        outputs.homeManagerModules.targets.darwin
        { home.username = "runner"; }
      ];
    }
  );

  "user@container" = home-manager-linux.lib.homeManagerConfiguration (
    shared
    // {
      pkgs = x86-Linux-pkgs;
      modules = [
        outputs.homeManagerModules.profiles.ephemeral
        outputs.homeManagerModules.targets.linux
        outputs.homeManagerModules.targets.generic-linux
        outputs.homeManagerModules.services.systemd
      ];
    }
  );
}

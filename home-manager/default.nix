{
  inputs,
  self,
  mkPkgs,
  ...
}:

let
  home-manager-linux = inputs.home-manager-linux;
  home-manager-darwin = inputs.home-manager-darwin;
  outputs = self.outputs;

  x86-Linux-pkgs = mkPkgs "x86_64-linux";
  shared = {
    extraSpecialArgs = {
      inherit outputs;
    };
  };
in
{
  flake.homeConfigurations = {
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

    "kachick@macbook" = home-manager-darwin.lib.homeManagerConfiguration (
      shared
      // {
        pkgs = mkPkgs "x86_64-darwin";
        modules = [
          outputs.homeManagerModules.kachick
          outputs.homeManagerModules.darwin
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
          outputs.homeManagerModules.kachick
          outputs.homeManagerModules.linux
          outputs.homeManagerModules.genericLinux
          outputs.homeManagerModules.lima-guest
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

    "github-actions@macos-15-intel" = home-manager-darwin.lib.homeManagerConfiguration (
      shared
      // {
        pkgs = mkPkgs "x86_64-darwin";
        modules = [
          outputs.homeManagerModules.kachick
          outputs.homeManagerModules.darwin
          { home.username = "runner"; }
        ];
      }
    );

    "user@container" = home-manager-linux.lib.homeManagerConfiguration (
      shared
      // {
        pkgs = x86-Linux-pkgs;
        modules = [
          outputs.homeManagerModules.genericUser
          outputs.homeManagerModules.linux
          outputs.homeManagerModules.genericLinux
          outputs.homeManagerModules.systemd
        ];
      }
    );
  };
}

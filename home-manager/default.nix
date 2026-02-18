{
  home-manager-linux,
  home-manager-darwin,
  mkPkgs,
}:

let
  x86-Linux-pkgs = mkPkgs "x86_64-linux";
in
{
  "kachick@wsl-ubuntu" = home-manager-linux.lib.homeManagerConfiguration {
    pkgs = x86-Linux-pkgs;
    modules = [
      ./kachick.nix
      ./linux.nix
      ./genericLinux.nix
      ./wsl.nix
    ];
  };

  "kachick@macbook" = home-manager-darwin.lib.homeManagerConfiguration {
    pkgs = mkPkgs "x86_64-darwin";
    modules = [
      ./kachick.nix
      ./darwin.nix
    ];
  };

  "kachick@lima" = home-manager-linux.lib.homeManagerConfiguration {
    pkgs = x86-Linux-pkgs;
    modules = [
      ./kachick.nix
      ./linux.nix
      ./genericLinux.nix
      ./lima-guest.nix
    ];
  };

  "github-actions@ubuntu-24.04" = home-manager-linux.lib.homeManagerConfiguration {
    pkgs = x86-Linux-pkgs;
    # Prefer "kachick" over "common" only here.
    # Using values as much as possible as actual values to create a robust CI
    modules = [
      ./kachick.nix
      ./linux.nix
      ./linux-ci.nix
      { home.username = "runner"; }
      ./genericLinux.nix
      ./systemd.nix
    ];
  };

  # macos-15-intel is the last x86_64-darwin runner. It is technically the right choice for respecting architecture of my old MacBook.
  # However it is too slow, almost 3x slower than Linux and macos-15(arm64) runner. So you should enable binary cache if use this runner
  # See https://github.com/kachick/dotfiles/issues/1198#issuecomment-3362312549 for detail
  "github-actions@macos-15-intel" = home-manager-darwin.lib.homeManagerConfiguration {
    pkgs = mkPkgs "x86_64-darwin";
    # Prefer "kachick" over "common" only here.
    # Using values as much as possible as actual values to create a robust CI
    modules = [
      ./kachick.nix
      ./darwin.nix
      { home.username = "runner"; }
    ];
  };

  "user@container" = home-manager-linux.lib.homeManagerConfiguration {
    pkgs = x86-Linux-pkgs;
    modules = [
      ./genericUser.nix
      ./linux.nix
      ./genericLinux.nix
      ./systemd.nix
    ];
  };
}

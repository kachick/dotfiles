{ pkgs, ... }:
{
  nixpkgs.allowedUnfreePackageNames = [
    "ludii-bin"
    "steam"
    "steam-unwrapped"
  ];

  environment.systemPackages = with pkgs; [
    local.ludii-bin
  ];

  programs.steam = {
    enable = true;
  };
}

{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    local.ludii-bin
  ];

  nixpkgs.allowedUnfreePackageNames = [ "ludii-bin" ];
}

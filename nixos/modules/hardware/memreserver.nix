# Imported from https://github.com/NixOS/nixpkgs/pull/225819 to fix GH-959

{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
{
  options = {
    hardware.memreserver = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = lib.mdDoc ''
          Enable memreserver sleep hook.
          Makes sure that GPUs with dedicated VRAM can suspend correctly.
        '';
      };
    };
  };

  config = mkIf config.hardware.memreserver.enable {
    systemd.services.memreserver = {
      description = "Sleep hook which frees up RAM needed to evacuate GPU VRAM into";
      before = [ "sleep.target" ];
      wantedBy = [ "sleep.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.my.memreserver}/bin/memreserver";
      };
    };
  };
}

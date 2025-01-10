{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.passSecretService;
in
{
  options.services.passSecretServiceRs = {
    enable = lib.mkEnableOption "pass secret service";

    package = lib.mkPackageOption pkgs.my "pass-secret-service-rs" { };
  };

  config = lib.mkIf cfg.enable {
    systemd.packages = [ cfg.package ];
    services.dbus.packages = [ cfg.package ];
  };

  meta.maintainers = with lib.maintainers; [ kachick ];
}

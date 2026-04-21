{ lib, ... }:

{
  options.profiles.recovery = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Whether to enable the recovery profile.
      When enabled, non-essential large packages and fonts are excluded to reduce ISO/disk size.
    '';
  };
}

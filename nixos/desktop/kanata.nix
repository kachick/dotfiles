{ pkgs, ... }:
{
  # Left Control + Space + Esc: Force exit
  #
  # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/nixos/modules/services/hardware/kanata.nix
  services.kanata = {
    enable = true;
    # Use same version as used in kanata-tray
    # Don't require kanata-with-cmd for now
    package = pkgs.unstable.kanata;

    keyboards = {
      # Intentionally setting alt to henkan and muhenkan even in JIS layouts to consider my mis-typing
      # tap-hold-press: tap-next in kmonad. See https://github.com/jtroo/kanata/issues/7#issuecomment-1196236726
      all = {
        # Don't use extraDefCfg to share same config with Windows and darwin
        configFile = ../../config/keyboards/kanata.kbd;
      };
    };
  };
}

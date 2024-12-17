{ pkgs, ... }:
{
  # Left Control + Space + Esc: Force exit
  #
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/hardware/kanata.nix
  services.kanata = {
    enable = true;

    package = pkgs.unstable.kanata; # TODO: Use stable since nixos-25.05. nixos-24.11 intentionally keeps 1.7.0-pre version

    keyboards = {
      # Intentionally setting alt to henkan and muhenkan even in JIS layouts to consider my mis-typing
      all = {
        config = ''
          (defsrc)
          (deflayermap (base)
            caps (tap-hold-press 200 200 caps lctl)
            lalt (tap-hold-press 200 200 lalt muhenkan)
          )
        '';
      };
    };
  };
}

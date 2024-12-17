{
  # Left Control + Space + Esc: Force exit
  #
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/hardware/kanata.nix
  services.kanata = {
    enable = true;

    keyboards = {
      # Intentionally setting alt to henkan and muhenkan even in JIS layouts to consider my mis-typing
      all = {
        config = ''
          (defsrc)
          (deflayermap (base)
            caps (tap-hold-press 200 200 caps lctl)
            lalt (tap-hold-press 200 200 lalt muhenkan)
            ralt (tap-hold-press 200 200 ralt henkan)
          )
        '';
      };
    };
  };
}

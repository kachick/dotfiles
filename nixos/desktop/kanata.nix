{ pkgs, ... }:
{
  # Left Control + Space + Esc: Force exit
  #
  # https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/hardware/kanata.nix
  services.kanata = {
    enable = true;

    # nixos-24.11 intentionally keeps 1.7.0-pre version
    # https://github.com/NixOS/nixpkgs/pull/354894
    # https://github.com/NixOS/nixpkgs/pull/351675#issuecomment-2440047546
    package = pkgs.unstable.kanata; # TODO: Use stable since nixos-25.05
    keyboards = {
      # Intentionally setting alt to henkan and muhenkan even in JIS layouts to consider my mis-typing
      # tap-hold-press: tap-next in kmonad. See https://github.com/jtroo/kanata/issues/7#issuecomment-1196236726
      all = {
        config = ''
          ;; Required to specify keys which should be considered in tap-hold-press (=spc, tab for alt-spc, alt-tab)
          ;; See https://github.com/jtroo/kanata/blob/fc850fab9da7d0bf377e215f0b923062e037ff64/docs/config.adoc?plain=1#L142-L143
          (defsrc caps lalt ralt spc tab)

          (defvar
            tap-timeout  200
            hold-timeout 200
            tt $tap-timeout
            ht $hold-timeout
          )

          (deflayermap (base)
            caps (tap-hold-press $tt $ht caps lctl)
            lalt (tap-hold-press $tt $ht muhenkan lalt)
            ralt (tap-hold-press $tt $ht henkan ralt)
          )
        '';
      };
    };
  };
}
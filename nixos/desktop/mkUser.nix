{ lib, ... }:

attrs:

let
  # Don't set "wheel" by default. Most distributions set sudoable.
  defaultGroups = [
    "networkmanager"
    "wheel" # Required by Nix trusted-users and WiFi.
    "input" # Finger print in GDM
    "uinput" # Added in GH-1156. Required by keyboard remappers. This will be unassigned when `hardware.uinput.enable = false`.
    "scanner"
    "lp" # Scanner
  ];

  additionalGroups = attrs.additionalGroups or [ ];
  extraGroups = lib.lists.unique (additionalGroups ++ defaultGroups);
  restAttrs = lib.attrsets.removeAttrs attrs [
    "extraGroups" # Invalid call for this generator
    "additionalGroups"
  ];
in
{
  inherit extraGroups;
  isNormalUser = true;
  description = "Generic user";
  packages = [
    # Don't install unfree packages such as spotify.
    # Use Web Player or PWA
  ];
}
// restAttrs

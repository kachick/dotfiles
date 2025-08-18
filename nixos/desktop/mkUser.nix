{ lib, ... }:

attrs:

let
  # Don't set "wheel" by default. Most distributions set sudoable.
  # TODO: Ensure adding WiFi supported Group
  defaultGroups = [
    "networkmanager"
    "wheel" # Required to use Nix trusted-users and WiFi.
    "input" # Finger print in GDM
    "uinput" # GH-1156
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

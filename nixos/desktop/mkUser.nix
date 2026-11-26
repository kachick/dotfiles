{ lib, ... }:

attrs:

# Fail-closed guard against the removed custom wrapper key.
assert lib.assertMsg (
  !(attrs ? additionalGroups)
) "mkUser: use standard extraGroups instead of additionalGroups";

let
  # Don't set "wheel" by default. Most distributions set sudoable.
  defaultGroups = [
    "networkmanager"
    "wheel" # Required by Nix trusted-users and WiFi.
    "input" # Finger print in GDM
    "uinput" # Added in GH-1156. Required by keyboard remappers. This will be unassigned when `hardware.uinput.enable = false`.
    "scanner"
    "lp" # Scanner
    "libvirtd" # GUI VM management
  ];
in
# Use lib.mkMerge instead of `//` so list options like extraGroups and packages
# combine naturally while conflicting scalar options fail evaluation instead of
# silently overriding defaults.
lib.mkMerge [
  {
    isNormalUser = true;
    extraGroups = defaultGroups;
    packages = [
      # Don't install unfree packages such as spotify.
      # Use Web Player or PWA
    ];
  }
  attrs
]

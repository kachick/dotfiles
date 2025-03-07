overrideAttrs:
{
  isNormalUser = true;
  description = "Generic user";
  extraGroups = [
    "networkmanager"
    "wheel"
    "input" # For finger print in GDM
    "scanner"
    "lp" # For scanner
  ];
  packages = [
    # Don't install unfree packages such as spotify.
    # Use Web Player or PWA
  ];
}
// overrideAttrs

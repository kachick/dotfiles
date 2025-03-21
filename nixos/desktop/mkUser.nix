overrideAttrs:
{
  isNormalUser = true;
  description = "Generic user";
  extraGroups = [
    "networkmanager"
    "wheel" # WiFi
    "input" # Finger print in GDM
    "scanner"
    "lp" # Scanner
  ];
  packages = [
    # Don't install unfree packages such as spotify.
    # Use Web Player or PWA
  ];
}
// overrideAttrs

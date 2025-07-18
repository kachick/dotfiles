extraAttrs:
{
  isNormalUser = true;
  description = "Generic user";
  extraGroups = [
    "networkmanager"
    "wheel" # WiFi
    "input" # Finger print in GDM
    "uinput" # GH-1156
    "scanner"
    "lp" # Scanner
  ];
  packages = [
    # Don't install unfree packages such as spotify.
    # Use Web Player or PWA
  ];
}
// extraAttrs

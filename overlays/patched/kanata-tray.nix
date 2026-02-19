{ kanata-tray, stdenvNoCC, ... }:
# "patched" might be inaccurate wording for this package. However this place is the better for my use. And not a lie. The channel might be different with upstream
kanata-tray.packages.${stdenvNoCC.hostPlatform.system}.kanata-tray

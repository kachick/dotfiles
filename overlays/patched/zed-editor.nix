{ zed-editor, stdenvNoCC, ... }:
# "patched" might be inaccurate wording for this package. However this place is the better for my use. And not a lie. The channel might be different with upstream
zed-editor.packages.${stdenvNoCC.hostPlatform.system}.default

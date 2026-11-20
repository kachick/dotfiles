{
  prev,
  fetchurl,
  ...
}:

# TODO: Drop this override once nixpkgs ships ibus > 1.5.34 that includes both commits.
# gnome-shell crashed (SIGSEGV in GC, `ibus_text_destroy`) after converting text with mozc.
# - Make IBusText own the converted IBusAttrList. Without this, gjs and IBusText share one reference.
#   Upstream issue: https://github.com/ibus/ibus/issues/2889
#   Upstream commit: https://github.com/ibus/ibus/commit/5bbe88a1936246185a65f76e58cc85871401e59a
# - Fix the memory leak introduced by the commit above.
#   Upstream issue: https://github.com/ibus/ibus/issues/2941
#   Upstream commit: https://github.com/ibus/ibus/commit/1a331e695d84fc6bae8f2d11c52d4776df49647b
# Use fetchurl instead of fetchpatch, because the raw commit patches apply as is.
prev.ibus.overrideAttrs (
  _finalAttrs: previousAttrs: {
    patches = (previousAttrs.patches or [ ]) ++ [
      (fetchurl {
        name = "ibus-GH-2889.patch";
        url = "https://github.com/ibus/ibus/commit/5bbe88a1936246185a65f76e58cc85871401e59a.patch";
        hash = "sha256-PIR8EU3+WwJnR2iqvhffB1FnhMS3qajmjd4ezQ+rdvM=";
      })
      (fetchurl {
        name = "ibus-GH-2941.patch";
        url = "https://github.com/ibus/ibus/commit/1a331e695d84fc6bae8f2d11c52d4776df49647b.patch";
        hash = "sha256-NYeb9kjT2pK15QmadeAXMxbQMUdoKxoncc+6cy6DK8Y=";
      })
    ];
  }
)

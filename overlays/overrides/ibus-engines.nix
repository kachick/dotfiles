{
  prev,
  unstable,
  ...
}:

# TODO: Drop this override and restore the stable package after nixos-26.11 is released.
# https://github.com/NixOS/nixpkgs/pull/531687 split mozc and ibus-mozc in nixpkgs-unstable.
# In stable (nixos-26.05), ibus-engines.mozc pointed to mozc with withIbus=true.
# Because mozc is now split, ibus-engines.mozc needs to point to unstable's ibus-mozc.
prev.ibus-engines
// {
  mozc = unstable.ibus-mozc;
}

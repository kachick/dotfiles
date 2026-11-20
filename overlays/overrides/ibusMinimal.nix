{ prev, ... }:

# TODO: Drop this file together with overlays/overrides/ibus.nix once nixpkgs ships ibus 1.5.35.
#
# Why keep ibusMinimal on unpatched upstream `prev.ibus` instead of `final.ibus`?
# By default, nixpkgs defines `ibusMinimal = ibus.override { libOnly = true; }`.
# If `ibusMinimal` picks up the overridden `ibus`, it changes the derivation hash of `sdl3`
# and triggers a massive rebuild chain (`sdl3` -> `ffmpeg`, `sdl2-compat`, `qemu`, `lima`,
# `zed-editor`, `electron`, `qtwebengine`, etc.).
# `sdl3` only reads a few header constants from `ibusMinimal` at compile time and never
# links to `libibus` at runtime.
# Mixing two ibus versions in the package set is dirty and diverges from normal nixpkgs
# design, but keeping this until upstream merges https://github.com/NixOS/nixpkgs/pull/589998
# is a practical trade-off to preserve upstream binary cache hits for unrelated heavy packages.
prev.ibusMinimal.override {
  ibus = prev.ibus;
}

{
  unstable,
  ...
}:

# TODO: Drop this override and restore the stable package after nixos-26.11 is released.
# https://github.com/NixOS/nixpkgs/pull/531687 updated mozc to 3.35.6354 in nixpkgs-unstable,
# which includes the fix for Super key hijacking (google/mozc#1059) and resolves the Bazel build issues.
unstable.mozc

{
  unstable,
  fetchpatch,
  ...
}:

# TODO: Drop this override once nix-update > 1.16.0 is released and available in nixpkgs-unstable.
# Fix an issue where meta.changelog is not updated when using --write-commit-message or --print-commit-message.
# Upstream issue: https://github.com/Mic92/nix-update/issues/657
# Upstream commit: https://github.com/Mic92/nix-update/commit/4074c2461b38345805331f4288e127e110b8aa06
unstable.nix-update.overrideAttrs (
  _finalAttrs: previousAttrs: {
    patches = (previousAttrs.patches or [ ]) ++ [
      (fetchpatch {
        name = "nix-update-GH-657.patch";
        url = "https://github.com/Mic92/nix-update/commit/4074c2461b38345805331f4288e127e110b8aa06.patch";
        hash = "sha256-EgaFjGejhF4ttQWGnF7s1OvaT/apR1DSmXrni2EZwlM=";
      })
    ];
  }
)

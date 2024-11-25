{
  edge-nixpkgs,
  nixpkgs,
  ...
}:
[
  (final: _prev: {
    my = import ../pkgs {
      pkgs = final.pkgs;
    };
  })

  (final: _prev: {
    unstable = import edge-nixpkgs {
      system = final.system;
    };
  })

  # Pacthed packages

  # TODO: Remove after https://github.com/NixOS/nixpkgs/pull/358952 introduced in one of depending channels
  (final: prev: {
    cloudflare-warp = prev.cloudflare-warp.overrideAttrs (
      finalAttrs: previousAttrs: rec {
        version = "2024.11.309";

        src = prev.fetchurl {
          url = "https://pkg.cloudflareclient.com/pool/noble/main/c/cloudflare-warp/cloudflare-warp_${version}.0_${previousAttrs.suffix}.deb";
          hash =
            {
              aarch64-linux = "sha256-pdCPN4NxaQqWNRPZY1CN03KnTdzl62vJ3JNfxGozI4k=";
              x86_64-linux = "sha256-THxXETyy08rBmvghrc8HIQ2cBSLeNVl8SkD43CVY/tE=";
            }
            .${prev.stdenv.hostPlatform.system}
              or (throw "Unsupported system: ${prev.stdenv.hostPlatform.system}");
        };
      }
    );
  })
]
++ nixpkgs.lib.optionals nixpkgs.lib.stdenv.hostPlatform.isLinux [
  (final: prev: {
    lima = prev.lima.overrideAttrs (
      finalAttrs: previousAttrs: {
        patches = [
          (prev.fetchpatch {
            # https://github.com/lima-vm/lima/pull/2943
            name = "lima-fix-systemd-target.patch";
            url = "https://github.com/lima-vm/lima/commit/071c3d7ab33237610eed0311249308b169f5ca5f.patch";
            hash = "sha256-bCHZv1qctr39PTRJ60SPnXLArXGl4/FV45G+5nDxMFY=";
          })
        ];
      }
    );
  })
]

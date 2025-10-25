{
  edge-nixpkgs,
  kanata-tray,
  ...
}:
[
  (final: _prev: {
    my = final.lib.packagesFromDirectoryRecursive {
      inherit (final) callPackage;
      directory = ../pkgs;
    };
  })

  (final: _prev: {
    unstable = import edge-nixpkgs {
      inherit (final) system config;
    };
  })

  # Patched and override existing name because of it is not cofigurable
  (final: prev: {
    # TODO: Use `services.gnome.gcr-ssh-agent.enable = false` since nixos-25.11
    #
    # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/by-name/gn/gnome-keyring/package.nix
    # Backport https://github.com/NixOS/nixpkgs/pull/379731 to disable SSH_AUTH_SOCK by gnome-keyring. This is required because of I should avoid GH-714 but realize GH-1015
    #
    # And it should be override the package it self, the module is not configurable for the package. https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/desktops/gnome/gnome-keyring.nix
    #
    # NOTE: This approcah might be wrong. See https://github.com/kachick/dotfiles/pull/1235/files#r2261225864 for detail
    gnome-keyring = prev.unstable.gnome-keyring;

    # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/by-name/mo/mozc/package.nix
    # The mozc package in nixpkgs often remains on old versions, primarily due to bazel dependency issues.
    # However, the latest mozc(2.31.5712.102 or later) includes a crucial patch to fix the Super key hijacking.
    mozc = prev.mozc.overrideAttrs (
      finalAttrs: previousAttrs: {
        patches = [
          (prev.fetchpatch {
            name = "GH-1277.patch";
            url = "https://patch-diff.githubusercontent.com/raw/google/mozc/pull/1059.patch?full_index=1";
            hash = "sha256-c67WPdvPDMxcduKOlD2z0M33HLVq8uO8jzJVQfBoxSY=";
          })
        ];
      }
    );
  })

  (final: prev: {
    # Patched packages should be put here if exist
    # Keep patched attr even if empty. To expose and runnable `nix build .#pname` for patched namespace
    patched = {
      # "patched" might be inaccurate wording for this package. However this place is the better for my use. And not a lie. The channel might be different with upstream
      inherit (kanata-tray.packages.${final.system}) kanata-tray;

      # pname = prev.unstable.pname.overrideAttrs (
      #   finalAttrs: previousAttrs: {
      #   }
      # );

      # Overriding non mkDerivation often makes hard to modify the hash(not src hash). See following workaround
      # rust:
      #   - https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/20
      #   - https://discourse.nixos.org/t/nixpkgs-overlay-for-mpd-discord-rpc-is-no-longer-working/59982/2
      # npm: https://discourse.nixos.org/t/npmdepshash-override-what-am-i-missing-please/50967/4

      # The lima package always takes long time to be reviewed and merged. So I can't depend on nixpkgs's binary cache :<
      # lima = prev.unstable.lima.overrideAttrs (
      #   finalAttrs: previousAttrs: {
      #     # Upstream PR: <UPDATEME>
      #     version = "<UPDATEME>";

      #     src = prev.fetchFromGitHub {
      #       owner = "lima-vm";
      #       repo = "lima";
      #       tag = "v${finalAttrs.version}";
      #       hash = "<UPDATEME>";
      #     };
      #   }
      # );

      # - Should locally override to use latest stable for now: https://github.com/NixOS/nixpkgs/pull/444028#issuecomment-3310117634
      # - OSS. Apache-2.0
      # - Reasonable choice rather than gemini-cli package. gemini-cli-bin is easier to track latest for now
      gemini-cli-bin = prev.unstable.gemini-cli-bin.overrideAttrs (
        finalAttrs: previousAttrs: {
          # Don't trust `gemini --version` results, for example, 0.6.1 actually returned `0.6.0`.
          version = "0.10.0";

          src = prev.fetchurl {
            url = "https://github.com/google-gemini/gemini-cli/releases/download/v${finalAttrs.version}/gemini.js";
            hash = "sha256-jwyx5HWjPi2S5GQFxV+VeuwrmjmLi+F1nzw4YMfNSiA=";
          };
        }
      );

      # Wait for merging https://github.com/NixOS/nixpkgs/pull/439590
      somo = prev.unstable.somo.overrideAttrs (
        finalAttrs: previousAttrs: {
          version = "1.3.0";

          src = prev.fetchFromGitHub {
            owner = "theopfr";
            repo = "somo";
            tag = "v${finalAttrs.version}";
            hash = "sha256-k7PDCylA6KR/S1dQDSMIoOELPYwJ25dz1u+PM6ITGKg=";
          };

          cargoDeps = final.rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) src;
            hash = "sha256-i3GmdBqCWPeslpr2zzOR4r8PgMP7EkC1mNFI7jSWO34=";
          };

          nativeCheckInputs = [
            prev.libredirect.hook
          ];

          preCheck = ''
            export NIX_REDIRECTS=/etc/services=${prev.iana-etc}/etc/services
          '';
        }
      );

      # Wait for releasing stable version which including https://github.com/yaneurao/YaneuraOu/commit/33dce0bfa363f63d99977c29b3d6ab40ff896138
      # See https://github.com/yaneurao/YaneuraOu/issues/304#issuecomment-3405888952 for detail
      yaneuraou = prev.unstable.yaneuraou.overrideAttrs (
        finalAttrs: previousAttrs: {
          version = "9.01-unstable";

          src = prev.fetchFromGitHub {
            owner = "yaneurao";
            repo = "YaneuraOu";
            rev = "33dce0bfa363f63d99977c29b3d6ab40ff896138";
            hash = "sha256-x0pHkCzby2HTGJoYN3/b9IiX1mIGrxjT2bTqB2lD0Q4=";
          };
        }
      );
    };
  })
]

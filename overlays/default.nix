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

  # Patched and override existing name because of it is not configurable
  (final: prev: {
    # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/by-name/li/linux-firmware/package.nix
    linux-firmware = prev.linux-firmware.overrideAttrs (
      finalAttrs: previousAttrs: rec {
        # Don't use "20251021" and the later versions for now. See GH-1328 for detail
        version = "20251011";

        src = prev.fetchFromGitLab {
          owner = "kernel-firmware";
          repo = "linux-firmware";
          tag = version;
          hash = "sha256-LFVrrVCqJORiHVnhIY0l7B4pRHI2MS0o/GbgOUDqO8s=";
        };
      }
    );

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
      lima = prev.unstable.lima.overrideAttrs (
        finalAttrs: previousAttrs: {
          # - 1.2.2 or higher is required to avoid some CVEs in the nerdctl dependency: https://github.com/NixOS/nixpkgs/pull/459093
          # - 2.0.0 includes patch for `limactl stop`: https://github.com/lima-vm/lima/pull/4303
          # - 2.0.1 includes patch for graceful shutdown: https://github.com/lima-vm/lima/pull/4310
          version = "2.0.1";

          src = prev.fetchFromGitHub {
            owner = "lima-vm";
            repo = "lima";
            tag = "v${finalAttrs.version}";
            hash = "sha256-GPrx4pvD6AxYIvAS+Mz8gFZ/Z7HeFFoHh3LOtAJ9bhI=";
          };

          vendorHash = "sha256-dA6zdrhN73Y8InlrCEdHgYwe5xbUlvKx0IMis2nWgWE=";
        }
      );

      # - Should locally override to use latest stable for now: https://github.com/NixOS/nixpkgs/pull/444028#issuecomment-3310117634
      # - OSS. Apache-2.0
      # - Reasonable choice rather than gemini-cli package. gemini-cli-bin is easier to track latest for now
      gemini-cli-bin = prev.unstable.gemini-cli-bin.overrideAttrs (
        finalAttrs: previousAttrs: {
          # Don't trust `gemini --version` results, for example, 0.6.1 actually returned `0.6.0`.
          version = "0.14.0";

          src = prev.fetchurl {
            url = "https://github.com/google-gemini/gemini-cli/releases/download/v${finalAttrs.version}/gemini.js";
            hash = "sha256-PF72evGnk4lpycvh1Keg7vRD0eDNUmr7Vel/9DIgM70=";
          };
        }
      );
    };
  })
]

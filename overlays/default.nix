{
  edge-nixpkgs,
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

  # Keep minimum patches as possible. Because of they can not use official binary cache. See GH-754

  # Patched and override existing name because of it is not cofigurable
  (final: prev: {
    # TODO: Use `services.gnome.gcr-ssh-agent.enable = false` since nixos-25.11
    #
    # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/by-name/gn/gnome-keyring/package.nix
    # Backport https://github.com/NixOS/nixpkgs/pull/379731 to disable SSH_AUTH_SOCK by gnome-keyring. This is required because of I should avoid GH-714 but realize GH-1015
    #
    # And it should be override the package it self, the module is not configurable for the package. https://github.com/NixOS/nixpkgs/blob/nixos-24.11/nixos/modules/services/desktops/gnome/gnome-keyring.nix
    gnome-keyring = prev.unstable.gnome-keyring;
  })

  # Pacthed packages
  (final: prev: {
    patched = {
      # TODO: Remove this overlay if merged and backported: https://github.com/NixOS/nixpkgs/pull/423960
      #
      # Use unstable channel for lima, it makes faster build especially patching with omitting additional agents: https://github.com/NixOS/nixpkgs/pull/415093
      # Also override lima-additional-guestagents in lima inputs if need the additional agents.
      lima = prev.unstable.lima.overrideAttrs (
        finalAttrs: previousAttrs: {
          # 1.2.0 includes https://github.com/lima-vm/lima/pull/3637 to fix GH-950
          version = "1.2.0";

          src = prev.fetchFromGitHub {
            owner = "lima-vm";
            repo = "lima";
            tag = "v${finalAttrs.version}";
            hash = "sha256-vrYsIYikoN4D3bxu/JTb9lMRcL5k9S6T473dl58SDW0=";
          };

          vendorHash = "sha256-8S5tAL7GY7dxNdyC+WOrOZ+GfTKTSX84sG8WcSec2Os=";
        }
      );
    };
  })
]

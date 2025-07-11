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
      # TODO: Remove this patch if merged and backported: https://github.com/NixOS/nixpkgs/pull/423960
      #
      # Use latest lima, it makes faster build especially patching: https://github.com/NixOS/nixpkgs/pull/415093
      lima = prev.unstable.lima.overrideAttrs (
        finalAttrs: previousAttrs:
        # This patch only required on NixOS. And avoid macOS build for now, at least on GHA macos runners, Nix 2.30.0 brokes the build
        # See following links
        # - https://github.com/NixOS/nixpkgs/pull/423960#issuecomment-3061050564
        # - https://github.com/actions/runner-images/issues/12574#issuecomment-3061038899
        # - https://github.com/kachick/nixpkgs-reviewing-workspace/pull/106#issuecomment-3062256632
        if prev.stdenv.hostPlatform.isLinux then
          {
            patches = [
              (prev.fetchpatch {
                # https://github.com/lima-vm/lima/pull/3637
                name = "lima-suppress-gssapi-warning.patch";
                url = "https://github.com/lima-vm/lima/pull/3637.patch?full_index=1";
                hash = "sha256-Q352EyM6vY/uhvm6s31Ff/IzHWd87EJm6WkFN9HFTJg=";
              })
            ];
          }
        else
          { }
      );
    };
  })
]

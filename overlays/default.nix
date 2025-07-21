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

  (final: prev: {
    # Pacthed packages should be put here if exist
    # Keep patched attr even if empty. To expose and runnable `nix build .#pname` for patched namespace
    patched = {
      # pname = prev.unstable.pname.overrideAttrs (
      #   finalAttrs: previousAttrs: {
      #   }
      # );
    };
  })
]

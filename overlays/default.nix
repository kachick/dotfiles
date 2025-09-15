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
  })

  (final: prev: {
    # Pacthed packages should be put here if exist
    # Keep patched attr even if empty. To expose and runnable `nix build .#pname` for patched namespace
    patched = {
      # pname = prev.unstable.pname.overrideAttrs (
      #   finalAttrs: previousAttrs: {
      #   }
      # );

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

      # I think there is no blocker to update this package.
      # See https://github.com/NixOS/nixpkgs/pull/436735#pullrequestreview-3225509510 for detail
      mdns-scanner = prev.unstable.mdns-scanner.overrideAttrs (
        finalAttrs: previousAttrs: {
          version = "0.24.0";

          src = prev.fetchFromGitHub {
            owner = "CramBL";
            repo = "mdns-scanner";
            tag = "v${finalAttrs.version}";
            hash = "sha256-0MHt/kSR6JvfCk08WIDPz6R9YYzDJ9RRTM6MU6sEwHk=";
          };

          cargoHash = "sha256-oJSsuU1vkisDISnp+/jFs1cWEVxr586l8yHbG6fkPjQ=";
        }
      );
    };
  })
]

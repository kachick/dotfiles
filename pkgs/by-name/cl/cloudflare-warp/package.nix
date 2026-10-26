{
  lib,
  pkgs,
  fetchurl,
  writeShellApplication,
  curl,
  jq,
  ripgrep,
  gnused,
  nix,
}:

# Why overrideAttrs on top of pkgs.unstable.cloudflare-warp instead of a full fork?
# 1. WARP depends heavily on upstream cloud services. Outdated clients may be blocked
#    quickly when upstream changes or incidents happen (for example, CA trust issues).
#    This repository needs to update it fast without waiting for nixpkgs channels.
# 2. While nixos/modules/cloudflare-warp.nix also imports the module from nixpkgs-unstable,
#    independent package updates can still cause small differences.
# 3. Reusing packaging logic (patchelf, desktop items, runtime dependencies) from
#    pkgs.unstable.cloudflare-warp minimizes drift from what the unstable NixOS module expects.
#
# Why decouple macOS (Darwin)?
# - Upstream nixpkgs updates often slow down because of macOS packaging and hash sync.
# - This repository does not use Cloudflare WARP on Darwin.
# - Cloudflare does not clearly promise the same version releases across Linux and macOS.
# Therefore, macOS sources are intentionally dropped and only Linux hashes are kept here.
#
# Why stay on Noble (Ubuntu 24.04)?
# - Cloudflare provides deb packages for multiple distros, but upstream nixpkgs uses Noble.
# - The autoPatchelfHook and buildInputs in nixpkgs are tested for Noble binaries.
#   Changing distro names brings risk of ABI and shared library mismatches during patching.
let
  version = "2026.8.2115.0";
  sources = {
    x86_64-linux = fetchurl {
      name = "cloudflare-warp_${version}_amd64.deb";
      url = "https://downloads.cloudflareclient.com/v1/download/noble-intel/version/${version}";
      hash = "sha256-AgkQeGDDxoUamrj9A2kBIaPeoxmbCE+Bl2IAcsZxzWg=";
    };
    aarch64-linux = fetchurl {
      name = "cloudflare-warp_${version}_arm64.deb";
      url = "https://downloads.cloudflareclient.com/v1/download/noble-arm/version/${version}";
      hash = "sha256-5UiONZYdZpieag9ZGnTUgTbCP0UNyn020tVCa2Op7uI=";
    };
  };
in
pkgs.unstable.cloudflare-warp.overrideAttrs (previousAttrs: {
  inherit version;

  src =
    sources.${pkgs.stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");

  passthru = (previousAttrs.passthru or { }) // {
    inherit sources;

    updateScript = lib.getExe (writeShellApplication {
      name = "update-cloudflare-warp";

      runtimeInputs = [
        curl
        jq
        ripgrep
        gnused
        nix
      ];

      text = builtins.readFile ./update.bash;
    });
  };

  meta = previousAttrs.meta // {
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})

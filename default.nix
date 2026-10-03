{
  system ? builtins.currentSystem,
  ...
}:
let
  lock = builtins.fromJSON (builtins.readFile ./flake.lock);
  nixpkgs-unstable = fetchTarball {
    url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    sha256 = lock.nodes.nixpkgs-unstable.locked.narHash;
  };
  pkgs =
    import
      (fetchTarball {
        url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.xz";
        sha256 = lock.nodes.nixpkgs.locked.narHash;
      })
      {
        inherit system;
        overlays = [
          (import ./overlays/unstable.nix nixpkgs-unstable)
          (import ./overlays/local.nix)
        ];
      };
in
pkgs.local // pkgs

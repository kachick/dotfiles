{
  nixpkgs,
  system,
  overlays,
  outputs,
  self,
}:

let
  pkgs = import nixpkgs {
    inherit system overlays;
    config.allowUnfreePredicate =
      pkg:
      builtins.elem (nixpkgs.lib.getName pkg) [
        "antigravity-cli"
        "antigravity-hub"
        "cloudflare-warp"
        "ludii-bin"
      ];
  };
in
(pkgs.lib.recursiveUpdate pkgs.pinned pkgs.local)
// {
  # Why not place `container-layered` and `microvm-sandbox` under `pkgs/by-name/`?
  #
  # Packages under `pkgs/by-name/` are loaded by `overlays/local.nix` via `final.callPackage`.
  # Both `nixosConfigurations` and `homeConfigurations` are built using those overlays, so a
  # package in `overlays/local.nix` cannot depend on `outputs.nixosConfigurations.*` or
  # `outputs.homeConfigurations.*` without causing an infinite recursion.
  #
  # `microvm-sandbox` wraps `outputs.nixosConfigurations.sandbox.config.microvm.declaredRunner`,
  # and `container-layered` consumes `outputs.homeConfigurations` and the installer config.
  # Keeping them here lets them read finalized flake outputs after overlays are evaluated,
  # while still exposing them under `outputs.packages.<system>.*` for `nix run` and Home Manager.
  container-layered = import ./containers/layered-image.nix {
    inherit pkgs;
    inherit (self) lastModifiedDate;
    homeConfigurations = outputs.homeConfigurations;
    corePackages = outputs.nixosConfigurations.installer.config.environment.corePackages;
  };
  microvm-sandbox = import ./nixos/hosts/sandbox/package.nix {
    inherit pkgs;
    declaredRunner = outputs.nixosConfigurations.sandbox.config.microvm.declaredRunner;
  };
}

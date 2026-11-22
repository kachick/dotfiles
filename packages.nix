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

{
  system ? builtins.currentSystem,
  ...
}:
let
  pkgs = import ./default.nix { inherit system; };
in
(import ./devShells.nix { inherit pkgs; }).default

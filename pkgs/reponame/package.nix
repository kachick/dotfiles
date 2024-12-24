{ pkgs, ... }:
pkgs.buildGo123Module rec {
  pname = "reponame";
  version = "0.0.1";
  default = pname;
  vendorHash = "sha256-1wycFQdf6sudxnH10xNz1bppRDCQjCz33n+ugP74SdQ=";
  src = ./.;

  # https://github.com/kachick/times_kachick/issues/316
  # TODO: Use env after nixos-25.05. See https://github.com/NixOS/nixpkgs/commit/905dc8d978b38b0439905cb5cd1faf79163e1f14#diff-b07c2e878ff713081760cd5dcf0b53bb98ee59515a22e6007cc3d974e404b220R24
  CGO_ENABLED = 0;

  meta = {
    description = "kachick/dotfiles => dotfiles, dotfiles => dotfiles";
    mainProgram = pname;
  };
}

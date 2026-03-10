{
  pkgs,
  lib,
  ...
}:
let
  keys = import ../../../config/ssh/keys.nix;
  # age supports multiple recipients. The archive can be decrypted by any of the corresponding private keys.
  ageArgs = lib.concatMap (key: [
    "--recipient"
    key
  ]) keys;
in
pkgs.writeShellApplication rec {
  name = "archive-home-files";
  text = ''
    GITLEAKS_CONFIG="${../../../config/gitleaks/.gitleaks.toml}"
    AGE_RECIPIENTS_ARGS=(${lib.escapeShellArgs ageArgs})
    ${builtins.readFile ./${name}.bash}
  '';
  runtimeInputs = with pkgs; [
    gnutar
    ripgrep
    coreutils
    age
    unstable.gitleaks
  ];
  meta = {
    description = "Backup and encrypt dotfiles generated with home-manager";
    longDescription = ''
      Backup dotfiles generated with home-manager.
      - Scans for secrets with gitleaks (follows symlinks to Nix store).
      - Encrypts the archive with age using all SSH public keys from config/ssh/keys.nix.
    '';
  };
}

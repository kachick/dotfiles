{ pkgs, ... }:
pkgs.writeShellApplication rec {
  name = "apply-system";
  # - Required to remove `errexit` for `||` operator
  # Don't add `xtrace` here, it displays much long `export`. Add it in code if you want
  bashOptions = [
    "nounset"
    "pipefail"
  ];
  text =
    (builtins.readFile ./${name}.bash)
    + ''
      mkdir --parents /etc/containers
      ln --symbolic --force '${../../config/containers/policy.json}' '/etc/containers/policy.json'
      ln --symbolic --force '${../../config/tailscaled/defaults.conf}' '/etc/default/tailscaled'
      ln --symbolic --force '${pkgs.my.tailscaled-service}' '/etc/systemd/system/tailscaled.service'
      systemctl enable tailscaled.service
    '';
  runtimeInputs = with pkgs; [
    coreutils # `uname`, `ln`, `mkdir`
  ];
  meta = {
    description = ''
      System level activation script for non NixOS Linux.
      Required to run with sudo. e.g. `sudoc nix run .#apply-system`
    '';
  };
}

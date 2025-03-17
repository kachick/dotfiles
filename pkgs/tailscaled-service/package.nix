{ substitute, tailscale }:
substitute {
  src = "${tailscale}/lib/systemd/system/tailscaled.service";
  # Revert https://github.com/NixOS/nixpkgs/commit/503caab7765f31d18bce7fa58b26d447bc413c17#diff-be05f1b8ce13345e8991a5ee802268e588cc6f10fd4d5fcc62c6c1300bd97896R36 for non NixOS use
  substitutions = [
    "--replace"
    "[Service]\nExecStart="
    "[Service]\nEnvironmentFile=/etc/default/tailscaled\nExecStart="
  ];
}

{
  pkgs,
  outputs,
  ...
}:

{
  home.packages = [
    outputs.packages.${pkgs.stdenv.hostPlatform.system}.microvm-sandbox
  ];
}

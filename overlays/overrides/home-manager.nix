{
  stdenv,
  home-manager-linux,
  home-manager-darwin,
  inetutils,
  ...
}:
(
  (if stdenv.hostPlatform.isDarwin then home-manager-darwin else home-manager-linux)
  .packages.${stdenv.hostPlatform.system}.home-manager.override
  {
    inherit inetutils;
  }
)

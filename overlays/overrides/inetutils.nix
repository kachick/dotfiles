{
  prev,
  stdenv,
  unstable,
  ...
}:
# Workaround for https://github.com/NixOS/nixpkgs/issues/488689
# The fix https://github.com/NixOS/nixpkgs/pull/482476 was merged into staging, but master still lacks the patch.
# This uses the previous version from unstable on Darwin to prevent CI failures.
# Essentially, this override is a dirty and fool approach for security fixes.
# But it is okay here because Darwin uses inetutils only for Home Manager.
# It is not global on Darwin.
if stdenv.hostPlatform.isDarwin then unstable.inetutils else prev.inetutils

{ pkgs, ... }:

{
  # Don't add unfree packages like vscode here for using in containers

  imports = [
    ./helix.nix
    ./micro.nix
    ./vim.nix
  ];

  # TODO: Update since merged https://github.com/nix-community/home-manager/pull/5455
  xdg.configFile."zed/settings.json".source = ../config/zed/settings.json;

  # Should have `root = true` in the file. - https://github.com/kachick/anylang-template/blob/45d7ef685ac4fd3836c3b32b8ce8fb45e909b771/.editorconfig#L1
  # Intentionally avoided to use https://github.com/nix-community/home-manager/blob/f58889c07efa8e1328fdf93dc1796ec2a5c47f38/modules/misc/editorconfig.nix
  home.file.".editorconfig".source =
    pkgs.fetchFromGitHub {
      owner = "kachick";
      repo = "anylang-template";
      rev = "45d7ef685ac4fd3836c3b32b8ce8fb45e909b771";
      sha256 = "sha256-F8xP4xCIS1ybvRm1xGB2USekGWKKxz0nokpY6gRxKBE=";
    }
    + "/.editorconfig";
}
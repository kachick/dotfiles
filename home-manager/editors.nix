{ ... }:

{
  # Don't add unfree packages like vscode here for using in containers

  imports = [
    ./helix.nix
    ./micro.nix
    ./vim.nix
  ];

  # TODO: Update since merged https://github.com/nix-community/home-manager/pull/5455
  xdg.configFile."zed/settings.json".source = ../config/zed/settings.json;
}

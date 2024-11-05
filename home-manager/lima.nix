{ config, lib, ... }:

{
  home.homeDirectory = lib.mkDefault "/home/${config.home.username}.local";
}

{ config, ... }:

{
  home.homeDirectory = "/home/${config.home.username}.local";
}

{ config, ... }:

{
  # https://github.com/lima-vm/lima/blame/0d058b0eaa2d1bafc867298503a9239e89c202a8/templates/default.yaml#L295-L296
  home.homeDirectory = "/home/${config.home.username}.linux";
}

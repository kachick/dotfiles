{ ... }:

{
  # https://github.com/nix-community/home-manager/blob/master/modules/programs/zellij.nix
  programs.zellij = {
    enable = true;

    settings = {
      # nord is a preset https://github.com/zellij-org/zellij/tree/v0.37.2/zellij-utils/assets/themes
      theme = "nord";
    };
  };
}

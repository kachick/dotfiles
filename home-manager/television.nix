{ ... }:
{
  # https://github.com/nix-community/home-manager/blob/ae755329092c87369b9e9a1510a8cf1ce2b1c708/modules/programs/television.nix
  programs.television = {
    enable = true;

    # Don't enable `enable*shIntegration` options for now, the applied keybindings will conflict with fzf.

    settings = {
      ui = {
        theme = "nord-dark";
      };
    };
  };
}

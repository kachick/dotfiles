{ ... }:
{
  # https://github.com/nix-community/home-manager/blob/ae755329092c87369b9e9a1510a8cf1ce2b1c708/modules/programs/television.nix
  programs.television = {
    enable = true;

    settings = {
      ui = {
        theme = "nord-dark";
        input_bar_position = "bottom";
        # orientation = "portrait"; # Available if https://github.com/alexpasmantier/television/pull/496 released
      };
    };
  };
}

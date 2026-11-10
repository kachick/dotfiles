{ ... }:
{
  # https://github.com/alexpasmantier/television
  xdg.configFile."television/config.toml".text = ''
    [ui]
    theme = "nord-dark"
    input_bar_position = "bottom"
    # orientation = "portrait" # Available if https://github.com/alexpasmantier/television/pull/496 released
  '';
}

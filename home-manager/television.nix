{ ... }:
{
  # https://github.com/alexpasmantier/television
  xdg.configFile."television/config.toml".text = ''
    [ui]
    theme = "nord-dark"
    input_bar_position = "bottom"
    # orientation = "portrait" # Available if https://github.com/alexpasmantier/television/pull/496 released
  '';

  # Align default files channel behavior with fzf by including hidden files and excluding .git.
  # This prevents false-positive "Command produced no output on stdout, checking stderr..." errors
  # when television runs in directories containing only dotfiles (such as fresh home directories).
  xdg.configFile."television/cable/files.toml".text = ''
    [metadata]
    name = "files"
    description = "A channel to select files and directories"
    requirements = ["fd", "bat"]

    [source]
    command = [
      { name = "Default", run = "fd -t f -H --exclude .git" },
      { name = "NoHidden", run = "fd -t f" },
    ]

    [preview]
    command = "bat -n --color=always '{}'"
    env = { BAT_THEME = "ansi" }

    [keybindings]
    shortcut = "f1"
    f12 = "actions:edit"
    ctrl-up = "actions:goto_parent_dir"

    [actions.edit]
    description = "Opens the selected entries with the default editor (falls back to vim)"
    command = "''${EDITOR:-vim} {}"
    shell = "bash"
    mode = "execute"

    [actions.goto_parent_dir]
    description = "Re-opens tv in the parent directory"
    command = "tv files .."
    mode = "execute"
  '';
}

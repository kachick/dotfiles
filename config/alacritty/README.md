# FAQ

## alacritty does not respect the config

There are 2 points

- Make sure the version `alacritty --version` is 0.13+. Older used YAML, newer uses TOML
- Make sure the OS and where is the root config put.\
  In many use-case, we expect and put most files into `$HOME/.config/alacritty/alacritty.toml`.\
  However windows expect `C:\Users\YOUR_NAME\AppData\Roaming\alacritty\alacritty.toml`.\
  Other imported files can be put under `$HOME` as above.\
  FYI, You can temporally specify the different root config as `alacritty --config-file $HOME\.config\alacritty\alacritty.toml`.

## How to copy and paste in alacritty?

[Add shift for basic keybinds, not just the ctrl+c, ctrl+v](https://github.com/alacritty/alacritty/issues/2383)

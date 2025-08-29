# Mozc

## It didn't change the keymap even if changed the config

On GNOME, you should require following command to apply changes for both keymap and ibus_config.

```bash
ibus write-cache; ibus restart
```

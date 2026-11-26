# Mozc

## Custom keymap and `config1.db`

Home Manager generates `$XDG_CONFIG_HOME/mozc/config1.db` from `keymap-msime-customized.txt` via `mozc-config` and syncs it as a writable file.
Use `mozc-config` to inspect or reload settings manually:

```bash
mozc-config dump
mozc-config diff
mozc-config reload
```

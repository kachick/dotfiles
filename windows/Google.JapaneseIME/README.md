# Google.JapaneseIME

You should know, this tool is based on Mozc

## Why separated from mozc config?

Similar to mozc config, however should have separated file.
Because it seems customized in upstream for Linux and Windows.
And windows files should have CRLF.

## It didn't change the keymap even if changed the config

As far as I know, we should reboot DE if changed the mozc config.
On GNOME, and Windows. So log-out once from Windows and re-login, it fixed.

# Keyboard

## HWDB

TODO: UPDATE ME with extracting from NixOS Config

## Kanata

## NixOS

It generates whole config from [partial config file](kanata.kbd).

## Windows

I have replaced "[Keyboard Manager(PowerToys)](https://github.com/microsoft/PowerToys) and [alt-ime-ahk](https://github.com/karakaram/alt-ime-ahk)" with [kanata](https://github.com/jtroo/kanata).

Use [partial config file](kanata.kbd) with comment-out the `defcfg` line.\
Download the `kanata_gui.exe` from [release page](https://github.com/jtroo/kanata/releases) and put it in same folder of config.\
And executing and registered in tray.\
I don't know why, the _gui does not respect `C:\Users\<Name>\.config\kanata.kbd` atleast in v1.7.0.

## QMK

### How to

Open <https://launcher.keychron.com/> on Windows. And import the JSON(Not yet tested)

### Schema

My device is [V3](https://github.com/qmk/qmk_firmware/tree/782f91a73a0f6d4128f9454509b4a207af269f8b/keyboards/keychron/v3/jis) Max JIS, however [this repository](https://github.com/qmk/qmk_firmware/tree/master/keyboards/keychron) only have V3 line without Max

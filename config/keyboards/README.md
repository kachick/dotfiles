# Keyboard

## HWDB

See [the definitions](https://github.com/search?q=repo%3Akachick%2Fdotfiles+extraHwdb&type=code)

## Kanata

Force exiting if I have faced to similar problems like GH-963

`Left Control` + `Space` + `Esc`

Then the process will die. You can restart it with `systemctl start kanata-all`.
Not just the `kanata`. You can check it with `systemctl list-unit-files "kanata*`.

```console
> systemctl list-unit-files "kanata*"
UNIT FILE STATE PRESET
kanata-all.service enabled ignored
```

And I added an escape hatch for caps lock. Which is only useable when keeping `F6` and `c + a + p`.

## Windows

I have replaced "[Keyboard Manager(PowerToys)](https://github.com/microsoft/PowerToys) and [alt-ime-ahk](https://github.com/karakaram/alt-ime-ahk)" with [kanata](https://github.com/jtroo/kanata).

Use [config file](kanata.kbd) which is same content of NixOS.\
Download the `kanata_gui.exe` from [release page](https://github.com/jtroo/kanata/releases) and put it in same folder of config.\
And executing and registered in tray.\
I don't know why, the _gui does not respect `C:\Users\<Name>\.config\kanata.kbd` atleast in v1.7.0.

## QMK

### How to

Open <https://launcher.keychron.com/> on Windows. And import the JSON(Not yet tested)

### Schema

My device is [V3](https://github.com/qmk/qmk_firmware/tree/782f91a73a0f6d4128f9454509b4a207af269f8b/keyboards/keychron/v3/jis) Max JIS, however [this repository](https://github.com/qmk/qmk_firmware/tree/master/keyboards/keychron) only have V3 line without Max

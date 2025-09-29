# Keyboard

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

## Linux

See [the HWDB definitions](https://github.com/search?q=repo%3Akachick%2Fdotfiles+extraHwdb&type=code).
I disable capslock, and dropped other keyremappers.

## Windows

Additionally using "[Keyboard Manager(PowerToys)](https://github.com/microsoft/PowerToys) to disable capslock.

## macOS

I use macOS built-in keyboard remapper to disable capslock.

## Hardware(QMK)

### How to

Open <https://launcher.keychron.com/> on Windows. And import the JSON(Not yet tested)

### Schema

My device is [V3](https://github.com/qmk/qmk_firmware/tree/782f91a73a0f6d4128f9454509b4a207af269f8b/keyboards/keychron/v3/jis) Max JIS, however [this repository](https://github.com/qmk/qmk_firmware/tree/master/keyboards/keychron) only have V3 line without Max

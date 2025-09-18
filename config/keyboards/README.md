# Keyboard

Since 2025-08-29, I dropped software keyremappers as possible as I can.\
So ANSI keyboards should switch IME with `Ctrl+Space` in all platforms.

## Linux

See [the HWDB definitions](https://github.com/search?q=repo%3Akachick%2Fdotfiles+extraHwdb&type=code).
I disable capslock, and dropped other keyremappers.

## Windows

I only use "[Keyboard Manager(PowerToys)](https://github.com/microsoft/PowerToys) to disable capslock.

## macOS

I only use macOS built-in keyboard remapper to disable capslock.

## Hardware(QMK)

### How to

Open <https://launcher.keychron.com/> on Windows. And import the JSON(Not yet tested)

### Schema

My device is [V3](https://github.com/qmk/qmk_firmware/tree/782f91a73a0f6d4128f9454509b4a207af269f8b/keyboards/keychron/v3/jis) Max JIS, however [this repository](https://github.com/qmk/qmk_firmware/tree/master/keyboards/keychron) only have V3 line without Max

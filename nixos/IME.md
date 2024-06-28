Enabling IME on chromium based apps like [Electron and wayland](https://github.com/electron/electron/issues/33662) requires some flags in the execution

```bash
google-chrome-stable --enable-wayland-ime
code --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime .
```

Remember to set `commandLineArgs` for that situation. Or make sure it will work with specified in electron-flags.conf.

Enabling IME on chromium based apps like Electron and wayland requires some flags in the execution

```bash
google-chrome-stable --enable-wayland-ime
code --enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime .
```

Remember to set `commandLineArgs` for that situation.

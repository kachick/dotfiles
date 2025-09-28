# Multi-Booting Windows and Linux

This document outlines potential issues and solutions when multi-booting Windows and another OS. Be aware that Windows updates can sometimes interfere with other operating systems.

## Windows Fast Startup Issues

Windows Fast Startup can cause several problems on the other OS.

### Known Problems

- [Unstable Wi-Fi](https://github.com/kachick/dotfiles/issues/663)
- [Incorrect timestamps in `dmesg`](https://github.com/kachick/dotfiles/issues/664)

### Solution: Disable Fast Startup

You need to disable Fast Startup to resolve these issues.

1. Follow the instructions here: <https://superuser.com/a/1347749>
2. As described in the link, you can verify the setting in the Windows Registry. Navigate to `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power`.
3. Ensure the value of `HiberbootEnabled` is `0`. If it is not, disable Fast Startup through the Control Panel.

### Notes

- This fix is only relevant for multi-boot setups and should not be applied to Windows-only environments.

# Multi-booting

If you need Multi-booting from some reasons, you should remember Windows may destroy other OS.\
Here is a note for me.

- Fast boot

  Problems

  - [Unstable Wifi](https://github.com/kachick/dotfiles/issues/663)
  - [Wrong timestamp on dmesg](https://github.com/kachick/dotfiles/issues/664)

  Solutions

  - <https://superuser.com/a/1347749>

  In regedit and paste HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power for the URL
  Make sure `HiberbootEnabled` is `0`, if not, change it from Control Panel

  Do not
  - Do not implement in winit or do not apply all environments for Windows Only PC

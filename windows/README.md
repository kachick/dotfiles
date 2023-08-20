# FAQ

## Configuration steps after installation packages

1. Change Dropbox storage path from `C:\Users`, default path made problems in System Restore.
   \
   See https://zmzlz.blogspot.com/2014/10/windows-dropbox.html for detail
1. Enable Bitlocker and backup the restore key

## How to install WSL2?

winget does not support it, run as follows

```powershell
wsl.exe --install
```

## How to export winget list?

```powershell
winget export --output "\\wsl.localhost\Ubuntu\home\kachick\repos\dotfiles\windows\winget-$(Get-Date -UFormat '%F').json"
```

## Which programs excluded winget-pkgs are needed?

- https://github.com/karakaram/alt-ime-ahk
- https://github.com/yuru7/PlemolJP
- https://www.realforce.co.jp/support/download/
- https://www.kioxia.com/ja-jp/personal/software/ssd-utility.html

## Why avoiding winget to install Firefox Developer Edition?

No Japanese locale is registered in winget yet, official installer is supporting.

- https://github.com/kachick/times_kachick/issues/235
- https://github.com/microsoft/winget-pkgs/tree/be851349a154acb14af6275812d79b70fadb9ddf/manifests/m/Mozilla/Firefox/DeveloperEdition/117.0b9

## How to open current directory in WSL2 with Windows Explorer?

In WSL shell

```bash
explorer.exe .
```

## How to move on Windows folder from WSL2?

```bash
z "$(wslpath 'G:\GoogleDrive')"
```

## I forgot to backup Bitlocker restore key 😋

https://account.microsoft.com/devices/recoverykey may help

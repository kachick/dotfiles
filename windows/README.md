# FAQ

## Configuration steps after installation packages

1. Change Dropbox storage path from `C:\Users`, default path made problems in System Restore.
   \
   See https://zmzlz.blogspot.com/2014/10/windows-dropbox.html for detail
1. On powershell
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
   \\wsl.localhost\Ubuntu\home\kachick\repos\dotfiles\windows\scripts\bootstrap.ps1 -DotfilesPath "\\wsl.localhost\Ubuntu\home\kachick\repos\dotfiles"
   ```
1. Exclude the `$PROFILE\Profile.ps1` from Anti Virus detection as Microsoft Defender
1. Enable Bitlocker and backup the restore key

## How to run go scripts in this repo?

After installed golang with winget

```console
Administrator in ~ psh
> go run github.com/kachick/dotfiles/cmd/disable_windows_beeps@0ed52e4341624d7216d0b97a9b9bbab3719a8377
2023/08/22 15:34:18 Completed to disable beeps, you need to restart Windows to activate settings
> go run github.com/kachick/dotfiles/cmd/disable_windows_beeps@0ed52e4341624d7216d0b97a9b9bbab3719a8377
2023/08/22 15:40:42 Skipped to create registry key, because it is already exists
```

Specifying with branch name with the @ref may use cache, then specify commit ref

## How to install WSL2?

winget does not support it, run as follows

```powershell
wsl.exe --install
```

## How to exclude PowerShell_profile? Why needed?

Reason: Avoid to slow executions of PowerShell, ngen.exe cannot compile latest pwsh

- Official: https://github.com/PowerShell/PowerShell/issues/14374#issuecomment-1416688062
- Better: https://superuser.com/a/1411591/120469
- Didn't: https://stackoverflow.com/questions/59341482/powershell-steps-to-fix-slow-startup
- How: https://support.microsoft.com/en-us/windows/add-an-exclusion-to-windows-security-811816c0-4dfd-af4a-47e4-c301afe13b26

One more noting, if you cannot find ngen.exe, dig under "C:\Windows\Microsoft.NET\Framework" as "C:\Windows\Microsoft.NET\Framework\v4.0.30319\ngen.exe"

## How to export winget list?

```powershell
winget export --output "\\wsl.localhost\Ubuntu\home\kachick\repos\dotfiles\windows\config\winget-pkgs-$(Get-Date -UFormat '%F')-raw.json"
```

It may be better to remove some packages such as `Mozilla.Firefox.DeveloperEdition`.

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

## How to write PowerShell scripts?

- https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines
- https://github.com/MicrosoftDocs/PowerShell-Docs/blob/a5caf0d1104144f66ea0d7b9e8b2980cf9c605e9/reference/docs-conceptual/community/contributing/powershell-style-guide.md
- https://github.com/kachick/learn_PowerShell

## How to get helps for PowerShell commands as `cmd --help` in Unix?

`Get-Help -Name New-Item`

Or visit to <https://learn.microsoft.com/ja-jp/powershell/module/microsoft.powershell.management/>

## How to realize `mkdir -p` in PowerShell?

No beautiful ways, I think. Read <https://stackoverflow.com/questions/19853340/powershell-how-can-i-suppress-the-error-if-file-alreadys-exists-for-mkdir-com>

## How to run PowerShell scripts in this repo?

If you faced following error, needed to enable the permission from Administrator's PowerShell terminal

```plaintext
.\windows\scripts\enable_verbose_context_menu.ps1: File \\wsl.localhost\Ubuntu\home\kachick\repos\dotfiles\windows\scripts\enable_verbose_context_menu.ps1 cannot be loaded. The file \\wsl.localhost\Ubuntu\home\kachick\repos\dotfiles\windows\scripts\enable_verbose_context_menu.ps1 is not digitally signed. You cannot run this script on the current system. For more information about running scripts and setting execution policy, see about_Execution_Policies at https://go.microsoft.com/fwlink/?LinkID=135170.
```

Executing loccal scrips just requires "RemoteSigned", but in wsl path, it is remote, so needed to relax more.

```powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
```

```console
> Get-ExecutionPolicy -List

        Scope ExecutionPolicy
        ----- ---------------
MachinePolicy       Undefined
   UserPolicy       Undefined
      Process       Undefined
  CurrentUser    Unrestricted
 LocalMachine       Undefined
```

After completed tasks, disable it as follows

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## History in PowerShell does not work...

If PowerShell in WindowsTerminal displaying as below,

```plaintext
PowerShell 7.3.6
Cannot load PSReadline module.  Console is running without PSReadline.
```

I have faced this problem when called `Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser`.\
Try to set the permission as `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

https://github.com/microsoft/terminal/issues/7257#issuecomment-1107700978

## Some PowerShell scripts did not change windows behaviors

https://answers.microsoft.com/en-us/windows/forum/all/windows-registry-changes-is-a-restart-always/e131b560-1d03-4b12-a32c-50df2bf12752

After registry editing, needs to restart windows or the process

## Why are you still using Google Japanese Input? Why don't you prefer Microsoft IME?

Pros for Microsoft IME

- Preinstalled by Windows
- It is having cloud translations now (Called as "予測変換")

Cons for Microsoft IME

- Needed to tab, not in space to get date as "きょう"
- No way to get date with ISO 8601 format

## How to remove Windows Widget?

Remove the noisy news widget as below!

```powershell
winget uninstall --id 9MSSGKG348SP
```

## How to copy and paste in alacritty?

[Add shift for basic keybinds, not just the ctrl+c, ctrl+v](https://github.com/alacritty/alacritty/issues/2383)

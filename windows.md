# FAQ

## Installation

Basically following codes will be done in PowerShell

1. Install WSL2
   ```powershell
   wsl.exe --install --distribution "Ubuntu-22.04"
   ```
1. On WSL2, download this repository. HTTPS may work even if ssh is not yet configured
   ```bash
   mkdir -p ~/repos
   cd ~/repos
   git clone https://github.com/kachick/dotfiles.git
   ```
1. Download the windows helper binaries from [GitHub releases](https://github.com/kachick/dotfiles/releases) or uploaded artifacts in [each workflow](https://github.com/kachick/dotfiles/actions/workflows/release.yml) summary
1. New session of pwsh
   ```powershell
   ./setup_windows_terminals.exe -dotfiles_path "\\wsl.localhost\Ubuntu-22.04\home\kachick\repos\dotfiles" -pwsh_profile_path "$PROFILE"
   ./disable_windows_beeps.exe
   ./enable_windows_verbose_context_menu.exe
   ```
1. Install some tools
   ```powershell
   winget import --import-file "\\wsl.localhost\Ubuntu-22.04\home\kachick\repos\dotfiles\windows\config\winget-pkgs-basic.json"
   winget import --import-file "\\wsl.localhost\Ubuntu-22.04\home\kachick\repos\dotfiles\windows\config\winget-pkgs-dev.json"
   winget import --import-file "\\wsl.localhost\Ubuntu-22.04\home\kachick\repos\dotfiles\windows\config\winget-pkgs-storage.json"
   ```
1. Remove needless pre-installed tools
   ```powershell
   # 9MSSGKG348SP is the Windows Widget(Windows Web Experience Pack)
   winget uninstall --id 9MSSGKG348SP
   ```
1. Change Dropbox storage path from `C:\Users`, default path made problems in System Restore.
   \
   See https://zmzlz.blogspot.com/2014/10/windows-dropbox.html for detail
1. Enable Bitlocker and backup the restore key

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
winget export --output "\\wsl.localhost\Ubuntu-22.04\home\kachick\repos\dotfiles\windows\config\winget-pkgs-$(Get-Date -UFormat '%F')-raw.json"
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
.\windows\scripts\enable_verbose_context_menu.ps1: File \\wsl.localhost\Ubuntu-22.04\home\kachick\repos\dotfiles\windows\scripts\enable_verbose_context_menu.ps1 cannot be loaded. The file \\wsl.localhost\Ubuntu-22.04\home\kachick\repos\dotfiles\windows\scripts\enable_verbose_context_menu.ps1 is not digitally signed. You cannot run this script on the current system. For more information about running scripts and setting execution policy, see about_Execution_Policies at https://go.microsoft.com/fwlink/?LinkID=135170.
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

## How to completely disable Microsoft IME after installed Google Japanese Input?

[#300](https://github.com/kachick/dotfiles/issues/300) is the steps.

## How to copy and paste in alacritty?

[Add shift for basic keybinds, not just the ctrl+c, ctrl+v](https://github.com/alacritty/alacritty/issues/2383)

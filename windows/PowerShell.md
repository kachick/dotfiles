# PowerShell

## How to print windows ENV?

AFAIK, %ENVNAME% can be replaced in PowerShell as follows

```console
~ psh
> $env:APPDATA
C:\Users\YOU\AppData\Roaming

~ psh
> $env:TMP
C:\Users\YOU\AppData\Local\Temp
```

[And golang source code is much helpful](https://github.com/golang/go/blob/f0d1195e13e06acdf8999188decc63306f9903f5/src/os/file.go#L500-L509)

## PowerShell startup is too slow

```plaintext
Loading personal and system profiles took 897ms.
```

1. Make sure you are using PSFzfHistory, not PSFzf
1. Make sure `pwsh -NoProfile` is fast
1. Restart the pwsh, if it is fast, cache maybe generated. The slow may happen when updated windows and/or the runtimes. (I guess)
1. Do NOT consider about `ngen.exe` solution as Googling say. It looks old for me.

Reason: ngen.exe cannot compile latest pwsh

- Official: <https://github.com/PowerShell/PowerShell/issues/14374#issuecomment-1416688062>
- Better: <https://superuser.com/a/1411591/120469>
- Didn't: <https://stackoverflow.com/questions/59341482/powershell-steps-to-fix-slow-startup>
- How: <https://support.microsoft.com/en-us/windows/add-an-exclusion-to-windows-security-811816c0-4dfd-af4a-47e4-c301afe13b26>

One more noting, if you cannot find ngen.exe, dig under "C:\Windows\Microsoft.NET\Framework" as "C:\Windows\Microsoft.NET\Framework\v4.0.30319\ngen.exe"

However, for my experience, pwsh is still much slow.\
I didn't try disabling defenders, but using nushell might be better for the Windows daily driver.

## How to write PowerShell scripts?

- <https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines>
- <https://github.com/MicrosoftDocs/PowerShell-Docs/blob/a5caf0d1104144f66ea0d7b9e8b2980cf9c605e9/reference/docs-conceptual/community/contributing/powershell-style-guide.md>
- <https://github.com/kachick/learn_PowerShell>

## History substring search in major shells for Windows

- PowerShell: Using <https://github.com/kelleyma49/PSFzf> made much slow, prefer <https://github.com/kachick/PSFzfHistory>
- nushell: But [it also does not have substring search like a zsh](https://github.com/nushell/nushell/discussions/7968)

## How to get helps for PowerShell commands as `cmd --help` in Unix?

`Get-Help -Name New-Item`

Or visit to <https://learn.microsoft.com/ja-jp/powershell/module/microsoft.powershell.management/>

## How to realize `mkdir -p` in PowerShell?

No beautiful ways, I think. Read <https://stackoverflow.com/questions/19853340/powershell-how-can-i-suppress-the-error-if-file-alreadys-exists-for-mkdir-com>

## How to run PowerShell scripts in this repo?

If you faced following error, needed to enable the permission from Administrator's PowerShell terminal

```plaintext
.\windows\scripts\enable_verbose_context_menu.ps1: File \\wsl.localhost\Ubuntu-24.04\home\kachick\repos\dotfiles\windows\scripts\enable_verbose_context_menu.ps1 cannot be loaded. The file \\wsl.localhost\Ubuntu-24.04\home\kachick\repos\dotfiles\windows\scripts\enable_verbose_context_menu.ps1 is not digitally signed. You cannot run this script on the current system. For more information about running scripts and setting execution policy, see about_Execution_Policies at https://go.microsoft.com/fwlink/?LinkID=135170.
```

Executing loccal scrips just requires "RemoteSigned", but in wsl path, it is remote, so needed to relax more.

```pwsh
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

```pwsh
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## History in PowerShell does not work

If PowerShell in WindowsTerminal displaying as below,

```plaintext
PowerShell 7.3.6
Cannot load PSReadline module.  Console is running without PSReadline.
```

I have faced this problem when called `Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser`.\
Try to set the permission as `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

<https://github.com/microsoft/terminal/issues/7257#issuecomment-1107700978>

## Some PowerShell scripts did not change windows behaviors

<https://answers.microsoft.com/en-us/windows/forum/all/windows-registry-changes-is-a-restart-always/e131b560-1d03-4b12-a32c-50df2bf12752>

After registry editing, needs to restart windows or the process

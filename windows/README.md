# Windows

## Installation

Basically following codes will be done in PowerShell

1. Download the windows helper binaries from [GitHub releases](https://github.com/kachick/dotfiles/releases) or uploaded artifacts in [each workflow](https://github.com/kachick/dotfiles/actions/workflows/windows.yml) summary
1. New session of pwsh
   ```pwsh
   ./winit-conf.exe run

   Install-Module -Name PSFzfHistory
   # $PROFILE is an "Automatic Variables", not ENV
   # https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables?view=powershell-7.4
   ./winit-conf.exe generate -path="config/powershell/Profile.ps1" > "$PROFILE"

   ./winit-reg.exe list
   ./winit-reg.exe run --all
   ```
1. Install some tools
   ```pwsh
   # Basically this may be same output of above `winit-conf.exe` log
   # Pick-up the winget-*.json outputs
   $env:TMP
   # => C:\Users\YOU\AppData\Local\Temp

   winget import --import-file "C:\Users\YOU\AppData\Local\Temp\winitRANDOM1\winget-pkgs-basic.json"
   # Optional
   winget import --import-file "C:\Users\YOU\AppData\Local\Temp\winitRANDOM2\winget-pkgs-storage.json"
   winget import --import-file "C:\Users\YOU\AppData\Local\Temp\winitRANDOM3\winget-pkgs-entertainment.json"
   ```
1. Remove needless pre-installed tools. Pick up from [bulk-uninstall.ps](./winget/bulk-uninstall.ps1)
1. Change Dropbox storage path from `C:\Users`, default path made problems in System Restore.\
   See https://zmzlz.blogspot.com/2014/10/windows-dropbox.html for detail
1. Enable Bitlocker and backup the restore key

## Workflow

1. `komorebic start --whkd`

## I forgot to backup Bitlocker restore key 😋

https://account.microsoft.com/devices/recoverykey may help

Param(
    [String]$DotfilesPath
)

mkdir ~/.config -ErrorAction SilentlyContinue
mkdir ~/.config/alacritty -ErrorAction SilentlyContinue
mkdir "$($env:APPDATA)/alacritty" -ErrorAction SilentlyContinue

Copy-Item "${DotfilesPath}\home\.config/starship.toml" -Destination ~/.config
Copy-Item "${DotfilesPath}\home\.config/alacritty/alacritty-common.yml" -Destination  ~/.config/alacritty
Copy-Item "${DotfilesPath}\home\.config/alacritty/alacritty-windows.yml" -Destination  "$($env:APPDATA)/alacritty/alacritty.yml"
Copy-Item "${DotfilesPath}\windows\config/Microsoft.PowerShell_profile.ps1" -Destination "$PROFILE"

Write-Output 'Completed, you need to restart terminals'

# Enable ctrl+a, ctrl+e
Set-PSReadLineOption -EditMode Emacs
Set-PSReadlineOption -BellStyle None

# https://github.com/microsoft/winget-cli/issues/2498#issuecomment-1553863082
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Invoke-Expression (&starship init powershell)

function la {
    Get-ChildItem -Force
}

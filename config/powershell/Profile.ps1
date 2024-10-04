# Enable ctrl+a, ctrl+e
Set-PSReadLineOption -EditMode Emacs
Set-PSReadlineOption -BellStyle None
Set-PSReadLineOption –HistoryNoDuplicates:$True

Set-PSReadlineOption -AddToHistoryHandler {
    param ($command)
    switch -regex ($command) {
        "^[a-z]$" {return $false}
        "tldr" {return $false}
        "exit" {return $false}
        "^function" {return $false}
    }
    return $true
}

function la {
    Get-ChildItem -Force
}

# https://github.com/microsoft/winget-cli/issues/2498#issuecomment-1553863082
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
# Specify `bash -i` to run the bash as interactive mode
[Environment]::SetEnvironmentVariable("RCLONE_PASSWORD_COMMAND", 'wsl.exe --exec bash -ic "pass show rclone"')
Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# https://github.com/kachick/PSFzfHistory
Set-FzfHistoryKeybind -Chord Ctrl+r

# Enable ctrl+a, ctrl+e
Set-PSReadLineOption -EditMode Emacs
Set-PSReadlineOption -BellStyle None
Set-PSReadLineOption –HistoryNoDuplicates:$True

Set-PSReadlineOption -AddToHistoryHandler {
    param ($command)
    switch -regex ($command) {
        "^[a-z]$" {return $false}
        "exit" {return $false}
    }
    return $true
}

function la {
    Get-ChildItem -Force
}

if (Get-Command -ErrorAction SilentlyContinue starship) {
    Invoke-Expression (&starship init powershell)
} else {
    # https://github.com/microsoft/winget-cli/issues/2498#issuecomment-1553863082
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

# TODO: Integrate https://github.com/kachick/PSFzfHistory here

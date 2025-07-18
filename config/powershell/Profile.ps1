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
    # Removed no-permissions and no-octal to adjust for Windows
    eza --long --all --group-directories-first --time-style=iso --color=always --no-user --sort=modified @Args
}

# New-TemporaryFile does not support directory creation. So copied from https://stackoverflow.com/a/34559554
function New-TemporaryDirectory {
    $parent = [System.IO.Path]::GetTempPath()
    $name = [System.IO.Path]::GetRandomFileName()
    New-Item -ItemType Directory -Path (Join-Path $parent $name)
}

function cdtemp {
    cd "$(New-TemporaryDirectory)"
}

# https://github.com/microsoft/winget-cli/issues/2498#issuecomment-1553863082
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
# Specify `bash -i` to run the bash as interactive mode
[Environment]::SetEnvironmentVariable("RCLONE_PASSWORD_COMMAND", 'wsl.exe --exec bash -ic "gopass show rclone"')
Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# https://github.com/kachick/PSFzfHistory
Set-FzfHistoryKeybind -Chord Ctrl+r

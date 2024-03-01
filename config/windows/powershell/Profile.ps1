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

# https://github.com/microsoft/winget-cli/issues/2498#issuecomment-1553863082
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Invoke-Expression (&starship init powershell)

function la {
    Get-ChildItem -Force
}

# PowerShell does not have option for history substring search
# So fzf will be a better option
# Following code worked, but enabling this made much slow starting up!
# It degraded #430 again
#
# Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
# Install-Module -Name PSFzf -RequiredVersion 2.5.22
# Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

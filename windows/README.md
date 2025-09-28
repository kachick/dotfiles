# Windows Setup Guide

This guide outlines the steps to configure a Windows environment using this dotfiles repository. These commands should be run in PowerShell.

## Initial Setup

1. **Enable Sudo:**
   Enable the `Sudo` feature. Windows will provide instructions on how to do this the first time you use it.

2. **Set XDG_CONFIG_HOME:**
   Set the `XDG_CONFIG_HOME` environment variable system-wide. This is respected by some applications like Nushell, though not all follow the full XDG Base Directory Specification.

   ```powershell
   sudo pwsh -Command "[Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', '$HOME\.config', 'Machine')"
   ```

3. **Download Helper Binaries:**
   Download the Windows helper binaries (`winit-conf.exe` and `winit-reg.exe`) from the latest successful workflow run [artifacts](https://github.com/kachick/dotfiles/actions/workflows/windows.yml).

4. **Run Configuration Scripts:**
   Start a new PowerShell session and run the following commands to apply configurations:

   ```powershell
   # Apply initial configurations
   ./winit-conf.exe run

   # Install PowerShell modules
   Install-Module -Name PSFzfHistory

   # Generate and apply the PowerShell profile
   # Note: $PROFILE is a PowerShell automatic variable, not a standard environment variable.
   # See: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables
   ./winit-conf.exe generate -path="config/powershell/Profile.ps1" > "$PROFILE"

   # List and apply Windows Registry settings
   ./winit-reg.exe list
   ./winit-reg.exe run --all
   ```

5. **Install Applications with winget:**
   The `winit-conf.exe` command generates `winget-*.json` files in your temporary directory. Use these files to install applications.

   ```powershell
   # Find your temporary directory path
   $env:TMP
   # Example output: C:\Users\YourUser\AppData\Local\Temp

   # Import the application lists. Replace the path with your actual temp path.
   winget import --import-file "C:\Users\YourUser\AppData\Local\Temp\winitRANDOM1\winget-pkgs-basic.json"

   # Optional application sets
   winget import --import-file "C:\Users\YourUser\AppData\Local\Temp\winitRANDOM2\winget-pkgs-storage.json"
   winget import --import-file "C:\Users\YourUser\AppData\Local\Temp\winitRANDOM3\winget-pkgs-entertainment.json"
   ```

6. **Uninstall Bloatware:**
   Review the [bulk-uninstall.ps1](./winget/bulk-uninstall.ps1) script and run the commands for any pre-installed applications you wish to remove.

7. **Enable BitLocker:**
   Enable BitLocker drive encryption and make sure to back up the recovery key to a safe location.

## Troubleshooting

### I forgot to back up my BitLocker recovery key!

You might be able to find your key at: <https://account.microsoft.com/devices/recoverykey>

# PowerShell Guide

This document provides a collection of tips, troubleshooting advice, and frequently asked questions for using PowerShell on Windows.

---

## General Tips and FAQ

### How do I print environment variables?

You can access environment variables using the `$env:` prefix.

```powershell
# Get the path to the AppData\Roaming directory
$env:APPDATA
# Output: C:\Users\YourUser\AppData\Roaming

# Get the path to the temporary directory
$env:TMP
# Output: C:\Users\YourUser\AppData\Local\Temp
```

For more details on how Go handles this, see the [Go source code](https://github.com/golang/go/blob/f0d1195e13e06acdf8999188decc63306f9903f5/src/os/file.go#L500-L509).

### How do I get help for a command?

Use the `Get-Help` cmdlet, similar to `--help` in Unix-like shells.

```powershell
Get-Help -Name New-Item
```

You can also find documentation online at the [PowerShell Module Browser](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/).

### How do I delegate arguments (like `"$@"` in Bash)?

Use splatting with `@Args`. See the official documentation on [Splatting](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-7.4#splatting-command-parameters) for more information.

### How do I create a directory recursively (like `mkdir -p`)?

There isn't a direct, elegant equivalent. `New-Item -ItemType Directory -Path "path/to/create"` works, but it will throw an error if the directory already exists. See [this Stack Overflow thread](https://stackoverflow.com/questions/19853340/powershell-how-can-i-suppress-the-error-if-file-alreadys-exists-for-mkdir-com) for various workarounds.

### Where can I find PowerShell scripting style guides?

- [Strongly Encouraged Development Guidelines](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines) (Official)
- [PowerShell Docs Style Guide](https://github.com/MicrosoftDocs/PowerShell-Docs/blob/main/reference/docs-conceptual/community/contributing/powershell-style-guide.md) (Official)
- [kachick/learn_PowerShell](https://github.com/kachick/learn_PowerShell) (Personal learning repository)

---

## Troubleshooting

### PowerShell startup is slow

If you see a message like `Loading personal and system profiles took 897ms`, try the following:

1. **Check your modules:** Ensure you are using `PSFzfHistory`, not the older `PSFzf`, which can be slower.
2. **Test without a profile:** Run `pwsh -NoProfile` to see if the slowness is caused by your profile scripts.
3. **Restart PowerShell:** If a no-profile shell is fast, try restarting your regular shell. Caches might be generated on the first run after an update to Windows or PowerShell itself.
4. **Avoid `ngen.exe`:** Older advice suggests using `ngen.exe`, but this is outdated and does not work with modern PowerShell.

If startup is still slow, consider using an alternative shell like Nushell for daily tasks.

### Scripts fail to run due to Execution Policy

If you see an error that a script "cannot be loaded" because it is "not digitally signed," you need to change the execution policy. This often happens when running scripts located in a WSL path (`\\wsl.localhost...`).

1. **Temporarily allow unrestricted scripts:**
   Open an **Administrator** PowerShell terminal and run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
   ```

2. **Verify the policy:**
   ```powershell
   Get-ExecutionPolicy -List
   # Ensure CurrentUser is Unrestricted
   ```

3. **Revert the policy:**
   After you have finished running your scripts, it is a good security practice to revert the policy.
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### `PSReadLine` module fails to load

If you see `Cannot load PSReadline module`, it is often also related to the execution policy. This can break features like command history.

- **Cause:** This can happen if the execution policy is set to `Undefined`.
- **Solution:** Set the policy to `RemoteSigned` or `Unrestricted` as described above.
  ```powershell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```
- **Context:** See [microsoft/terminal issue #7257](https://github.com/microsoft/terminal/issues/7257#issuecomment-1107700978).

### Registry changes are not applied immediately

Changes made to the Windows Registry often require a restart of the affected process (e.g., `explorer.exe`) or a full system reboot to take effect. See [this Microsoft forum discussion](https://answers.microsoft.com/en-us/windows/forum/all/windows-registry-changes-is-a-restart-always/e131b560-1d03-4b12-a32c-50df2bf12752) for context.

---

## Shell-Specific Features

### History Substring Search

- **PowerShell:** For fast history search, use [kachick/PSFzfHistory](https://github.com/kachick/PSFzfHistory) instead of the older `PSFzf`.
- **Nushell:** As of now, Nushell does not have a built-in Zsh-like substring search. See [nushell/nushell discussion #7968](https://github.com/nushell/nushell/discussions/7968).

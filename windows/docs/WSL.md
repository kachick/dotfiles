# Windows Subsystem for Linux

## How to install WSL2?

winget does not support it, run as follows

## How to open current directory in WSL2 with Windows Explorer?

In WSL shell

```bash
explorer.exe .
```

## How to move on Windows folder from WSL2?

```bash
z "$(wslpath 'G:\GoogleDrive')"
```

## Login shell has been broken in WSL2

```pwsh
wsl --user root
```

# Visual Studio Code Extension Management

This document describes how to manage Visual Studio Code extensions via the command line, which is useful for automating setup without relying on Settings Sync.

---

### Backing Up Installed Extensions

To save a list of all currently installed extensions to a file, run the following command. The list will be sorted alphabetically.

```bash
code --list-extensions | sort > ./config/vscode/extensions.txt
```

### Bulk Installing Extensions from a List

To install all extensions listed in the `extensions.txt` file, use the following command. This method is based on the approach described in [this Stack Overflow answer](https://stackoverflow.com/a/60805086).

```bash
xargs -n 1 code --install-extension < ./config/vscode/extensions.txt
```

_Note: The original command used `--no-run-if-empty` and `--max-lines=1`, which are effective but less portable. `-n 1` is a more common equivalent for `--max-lines=1`._
